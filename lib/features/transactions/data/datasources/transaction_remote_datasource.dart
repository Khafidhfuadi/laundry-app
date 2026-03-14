import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class TransactionRemoteDatasource {
  Future<List<TransactionEntity>> getTransactions({
    String? status,
    String? outletId,
    DateTime? startDate,
    DateTime? endDate,
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

  Map<String, dynamic> _withoutPaymentReceivedAt(Map<String, dynamic> payload) {
    final copy = Map<String, dynamic>.from(payload);
    copy.remove('payment_received_at');
    return copy;
  }

  Map<String, dynamic> _withoutRefundColumns(Map<String, dynamic> payload) {
    final copy = Map<String, dynamic>.from(payload);
    copy.remove('refund_amount');
    copy.remove('refund_at');
    return copy;
  }

  Map<String, dynamic> _withoutUnsupportedColumns(
    Map<String, dynamic> payload,
  ) {
    final copy = Map<String, dynamic>.from(payload);
    copy.remove('payment_received_at');
    copy.remove('refund_amount');
    copy.remove('refund_at');
    return copy;
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    String? status,
    String? outletId,
    DateTime? startDate,
    DateTime? endDate,
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

    if (startDate != null) {
      query = query.gte('created_at', startDate.toUtc().toIso8601String());
    }
    if (endDate != null) {
      final exclusiveEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));
      query = query.lt('created_at', exclusiveEnd.toUtc().toIso8601String());
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
    Map<String, dynamic> payload = transaction.toJson();
    if (transaction.paidAmount > 0 && payload['payment_received_at'] == null) {
      payload['payment_received_at'] = DateTime.now().toUtc().toIso8601String();
    }

    late final dynamic headerResponse;
    try {
      headerResponse = await supabaseClient
          .from('transactions')
          .insert(payload)
          .select()
          .single();
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('payment_received_at')) {
        headerResponse = await supabaseClient
            .from('transactions')
            .insert(_withoutPaymentReceivedAt(payload))
            .select()
            .single();
      } else if (message.contains('refund_amount') ||
          message.contains('refund_at')) {
        headerResponse = await supabaseClient
            .from('transactions')
            .insert(_withoutRefundColumns(payload))
            .select()
            .single();
      } else {
        rethrow;
      }
    }

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
    final tx = await getTransactionById(id);
    final Map<String, dynamic> updates = {'status': newStatus};
    final now = DateTime.now().toUtc().toIso8601String();

    if (newStatus == 'PROCESS') {
      updates['processed_at'] = now;
    } else if (newStatus == 'READY') {
      updates['ready_at'] = now;
    } else if (newStatus == 'COMPLETED' || newStatus == 'PICKED_UP') {
      updates['completed_at'] = now;
    } else if (newStatus == 'CANCELLED') {
      final refundableAmount = tx.paidAmount.clamp(0, double.infinity);
      if (refundableAmount > 0) {
        updates['refund_amount'] = refundableAmount;
        updates['refund_at'] = now;
      }
    }

    try {
      await supabaseClient.from('transactions').update(updates).eq('id', id);
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('refund_amount') || message.contains('refund_at')) {
        await supabaseClient
            .from('transactions')
            .update(_withoutRefundColumns(updates))
            .eq('id', id);
      } else if (message.contains('payment_received_at')) {
        await supabaseClient
            .from('transactions')
            .update(_withoutUnsupportedColumns(updates))
            .eq('id', id);
      } else {
        rethrow;
      }
    }

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
    final updates = <String, dynamic>{
      'paid_amount': newPaid,
      'payment_status': paymentStatus,
    };

    if (amountPaid > 0) {
      updates['payment_received_at'] = DateTime.now().toUtc().toIso8601String();
    }

    try {
      await supabaseClient.from('transactions').update(updates).eq('id', id);
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('payment_received_at')) {
        await supabaseClient
            .from('transactions')
            .update(_withoutPaymentReceivedAt(updates))
            .eq('id', id);
      } else if (message.contains('refund_amount') ||
          message.contains('refund_at')) {
        await supabaseClient
            .from('transactions')
            .update(_withoutRefundColumns(updates))
            .eq('id', id);
      } else {
        rethrow;
      }
    }

    return getTransactionById(id);
  }
}
