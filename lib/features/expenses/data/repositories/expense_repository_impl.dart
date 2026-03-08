import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDatasource remoteDatasource;

  ExpenseRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    required String outletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final expenses = await remoteDatasource.getExpenses(
        outletId: outletId,
        startDate: startDate,
        endDate: endDate,
      );
      return right(expenses);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> addExpense(
    ExpenseEntity expense,
  ) async {
    try {
      final added = await remoteDatasource.addExpense(expense);
      return right(added);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      await remoteDatasource.deleteExpense(id);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
