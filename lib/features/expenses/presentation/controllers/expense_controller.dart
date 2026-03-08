import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

final expenseRemoteDatasourceProvider = Provider<ExpenseRemoteDatasource>((
  ref,
) {
  return ExpenseRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.watch(expenseRemoteDatasourceProvider));
});

class ExpenseController extends AsyncNotifier<List<ExpenseEntity>> {
  late ExpenseRepository _repository;
  String? _currentOutletId;

  @override
  FutureOr<List<ExpenseEntity>> build() async {
    _repository = ref.watch(expenseRepositoryProvider);
    // Secara default tidak mengambil jika tidak ada outlet id yang aktif.
    return [];
  }

  Future<void> loadExpenses(String outletId) async {
    _currentOutletId = outletId;
    state = const AsyncValue.loading();
    final result = await _repository.getExpenses(outletId: outletId);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (expenses) => AsyncValue.data(expenses),
    );
  }

  Future<bool> addExpense(ExpenseEntity expense) async {
    final result = await _repository.addExpense(expense);
    return result.fold((failure) => false, (added) {
      if (_currentOutletId != null) {
        loadExpenses(_currentOutletId!);
      }
      return true;
    });
  }

  Future<bool> deleteExpense(String id) async {
    final result = await _repository.deleteExpense(id);
    return result.fold((failure) => false, (_) {
      if (_currentOutletId != null) {
        loadExpenses(_currentOutletId!);
      }
      return true;
    });
  }
}

final expenseControllerProvider =
    AsyncNotifierProvider<ExpenseController, List<ExpenseEntity>>(
      ExpenseController.new,
    );
