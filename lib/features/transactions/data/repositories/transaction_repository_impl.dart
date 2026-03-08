import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDatasource remoteDatasource;

  TransactionRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    String? status,
    String? outletId,
  }) async {
    try {
      final transactions = await remoteDatasource.getTransactions(
        status: status,
        outletId: outletId,
      );
      return right(transactions);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(
    String id,
  ) async {
    try {
      final transaction = await remoteDatasource.getTransactionById(id);
      return right(transaction);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> createTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final created = await remoteDatasource.createTransaction(transaction);
      return right(created);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> updateTransactionStatus(
    String id,
    String newStatus,
  ) async {
    try {
      final updated = await remoteDatasource.updateTransactionStatus(
        id,
        newStatus,
      );
      return right(updated);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> checkoutPayment(
    String id,
    double amountPaid,
  ) async {
    try {
      final updated = await remoteDatasource.checkoutPayment(id, amountPaid);
      return right(updated);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
