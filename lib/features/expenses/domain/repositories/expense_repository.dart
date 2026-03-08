import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/expense_entity.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    required String outletId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, ExpenseEntity>> addExpense(ExpenseEntity expense);
  Future<Either<Failure, void>> deleteExpense(String id);
}
