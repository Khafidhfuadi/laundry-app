import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class TransactionRemoteDatasource {
  Future<List<TransactionEntity>> getTransactions({
    String? status,
    String? outletId,
  });
  Future<TransactionEntity> getTransactionById(String id);
  Future<TransactionEntity> createTransaction(TransactionEntity transaction);
  Future<TransactionEntity> updateTransactionStatus(
    String id,
    String newStatus,
  );
  Future<TransactionEntity> checkoutPayment(String id, double amountPaid);
}

class TransactionRemoteDatasourceImpl implements TransactionRemoteDatasource {
  final SupabaseClient supabaseClient;

  TransactionRemoteDatasourceImpl(this.supabaseClient);

  // Helper konstan query relasional
  static const String _selectQuery = '''
    *,
    customers (*),
    outlets (*),
    perfumes (*),
    transaction_items (
      *,
      service_variants (
        *,
        services (
          *,
          service_categories (name)
        )
      )
    )
  ''';

  @override
  Future<List<TransactionEntity>> getTransactions({
    String? status,
    String? outletId,
  }) async {
    PostgrestFilterBuilder query = supabaseClient
        .from('transactions')
        .select(_selectQuery);

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    if (outletId != null && outletId.isNotEmpty) {
      query = query.eq('outlet_id', outletId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((e) => TransactionEntity.fromJson(e))
        .toList();
  }

  @override
  Future<TransactionEntity> getTransactionById(String id) async {
    final response = await supabaseClient
        .from('transactions')
        .select(_selectQuery)
        .eq('id', id)
        .single();

    return TransactionEntity.fromJson(response);
  }

  @override
  Future<TransactionEntity> createTransaction(
    TransactionEntity transaction,
  ) async {
    // Memanggil procedure `create_transaction` RPC di Supabase jika ada,
    // atau menggunakan multiple insert. Di sini kita contohkan multiple insert
    // dengan skenario fallback sederhana jika belum ada RPC

    // 1. Insert header
    final headerResponse = await supabaseClient
        .from('transactions')
        .insert(transaction.toJson())
        .select()
        .single();

    final transactionId = headerResponse['id'];

    // 2. Insert items
    if (transaction.items.isNotEmpty) {
      final itemsData = transaction.items.map((e) {
        final json = e.toJson();
        json['transaction_id'] = transactionId;
        return json;
      }).toList();

      await supabaseClient.from('transaction_items').insert(itemsData);
    }

    return getTransactionById(transactionId as String);
  }

  @override
  Future<TransactionEntity> updateTransactionStatus(
    String id,
    String newStatus,
  ) async {
    final Map<String, dynamic> updates = {'status': newStatus};
    final now = DateTime.now().toUtc().toIso8601String();

    if (newStatus == 'PROCESS') {
      updates['processed_at'] = now;
    } else if (newStatus == 'READY') {
      updates['ready_at'] = now;
    } else if (newStatus == 'COMPLETED' || newStatus == 'PICKED_UP') {
      updates['completed_at'] = now;
    }

    await supabaseClient.from('transactions').update(updates).eq('id', id);

    return getTransactionById(id);
  }

  @override
  Future<TransactionEntity> checkoutPayment(
    String id,
    double amountPaid,
  ) async {
    // Logika payment status (PARTIAL/PAID) biasanya bisa di handle di Supabase Edge Function
    // atau di klien seperti berikut (asumsi total harga dibaca secara utuh di server,
    // di klien kita cukup passing amountPaid, payment_status diupdate):

    final tx = await getTransactionById(id);
    final newPaid = tx.paidAmount + amountPaid;
    final String paymentStatus = newPaid >= tx.totalPrice ? 'PAID' : 'PARTIAL';

    await supabaseClient
        .from('transactions')
        .update({'paid_amount': newPaid, 'payment_status': paymentStatus})
        .eq('id', id);

    return getTransactionById(id);
  }
}
