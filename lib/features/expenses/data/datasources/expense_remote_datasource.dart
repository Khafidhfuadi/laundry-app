import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/expense_entity.dart';

abstract class ExpenseRemoteDatasource {
  Future<List<ExpenseEntity>> getExpenses({
    required String outletId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<ExpenseEntity> addExpense(ExpenseEntity expense);
  Future<void> deleteExpense(String id);
}

class ExpenseRemoteDatasourceImpl implements ExpenseRemoteDatasource {
  final SupabaseClient supabaseClient;

  ExpenseRemoteDatasourceImpl(this.supabaseClient);

  @override
  Future<List<ExpenseEntity>> getExpenses({
    required String outletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    PostgrestFilterBuilder query = supabaseClient.from('expenses').select();

    query = query.eq('outlet_id', outletId);

    if (startDate != null) {
      query = query.gte('expense_date', startDate.toUtc().toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('expense_date', endDate.toUtc().toIso8601String());
    }

    final response = await query.order('expense_date', ascending: false);
    return (response as List).map((e) => ExpenseEntity.fromJson(e)).toList();
  }

  @override
  Future<ExpenseEntity> addExpense(ExpenseEntity expense) async {
    final response = await supabaseClient
        .from('expenses')
        .insert(expense.toJson())
        .select()
        .single();

    return ExpenseEntity.fromJson(response);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await supabaseClient.from('expenses').delete().eq('id', id);
  }
}
