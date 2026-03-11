import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

final transactionRemoteDatasourceProvider =
    Provider<TransactionRemoteDatasource>((ref) {
      return TransactionRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
    });

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    ref.watch(transactionRemoteDatasourceProvider),
  );
});

class TransactionController extends AsyncNotifier<List<TransactionEntity>> {
  late TransactionRepository _repository;

  @override
  FutureOr<List<TransactionEntity>> build() async {
    _repository = ref.watch(transactionRepositoryProvider);
    return _fetchTransactions();
  }

  Future<List<TransactionEntity>> _fetchTransactions() async {
    final result = await _repository.getTransactions();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (transactions) => transactions,
    );
  }

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTransactions());
  }

  Future<bool> updateStatus(String id, String newStatus) async {
    final result = await _repository.updateTransactionStatus(id, newStatus);
    return result.fold((failure) => false, (_) {
      // Hanya menyegarkan list yang ada alih-alih loading full
      loadTransactions();
      return true;
    });
  }

  Future<bool> createTransaction(TransactionEntity transaction) async {
    final result = await _repository.createTransaction(transaction);
    return result.fold((failure) {
      print('Gagal buat transaksi dari repository: ${failure.message}');
      return false;
    }, (_) {
      loadTransactions();
      return true;
    });
  }

  Future<bool> addPayment(String id, double amountPaid) async {
    final result = await _repository.checkoutPayment(id, amountPaid);

    return result.fold((failure) => false, (_) {
      loadTransactions();
      return true;
    });
  }
}

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, List<TransactionEntity>>(
      TransactionController.new,
    );

final transactionDetailProvider =
    FutureProvider.family<TransactionEntity, String>((ref, id) async {
      final repository = ref.watch(transactionRepositoryProvider);
      final result = await repository.getTransactionById(id);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (transaction) => transaction,
      );
    });
