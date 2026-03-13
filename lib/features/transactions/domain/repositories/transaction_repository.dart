import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    String? status,
    String? outletId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, TransactionEntity>> getTransactionById(String id);
  Future<Either<Failure, TransactionEntity>> createTransaction(
    TransactionEntity transaction,
  );
  Future<Either<Failure, TransactionEntity>> updateTransactionStatus(
    String id,
    String newStatus,
  );
  Future<Either<Failure, TransactionEntity>> checkoutPayment(
    String id,
    double amountPaid,
  );
}
