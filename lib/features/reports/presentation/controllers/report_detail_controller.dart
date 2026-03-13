import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../expenses/data/datasources/expense_remote_datasource.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../transactions/data/datasources/transaction_remote_datasource.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/report_detail.dart';

final _reportDetailTransactionDatasourceProvider =
    Provider<TransactionRemoteDatasource>((ref) {
      return TransactionRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
    });

final _reportDetailExpenseDatasourceProvider =
    Provider<ExpenseRemoteDatasource>((ref) {
      return ExpenseRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
    });

final reportDetailControllerProvider =
    AsyncNotifierProvider<ReportDetailController, ReportDetailState>(
      ReportDetailController.new,
    );

class ReportDetailController extends AsyncNotifier<ReportDetailState> {
  late TransactionRemoteDatasource _txDs;
  late ExpenseRemoteDatasource _expDs;

  @override
  FutureOr<ReportDetailState> build() async {
    _txDs = ref.watch(_reportDetailTransactionDatasourceProvider);
    _expDs = ref.watch(_reportDetailExpenseDatasourceProvider);
    return ReportDetailState.empty();
  }

  Future<void> loadDetail({
    required String outletId,
    required ReportDetailType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final txFuture = _txDs.getTransactions(
        outletId: outletId,
        startDate: startDate,
        endDate: endDate,
      );
      final expFuture = _expDs.getExpenses(
        outletId: outletId,
        startDate: startDate,
        endDate: endDate,
      );
      final results = await Future.wait([txFuture, expFuture]);

      final transactions = results[0] as List<TransactionEntity>;
      final expenses = results[1] as List<ExpenseEntity>;

      final detail = buildReportDetailState(
        type: type,
        startDate: startDate,
        endDate: endDate,
        transactions: transactions,
        expenses: expenses,
      );

      state = AsyncValue.data(detail);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

ReportDetailState buildReportDetailState({
  required ReportDetailType type,
  required DateTime startDate,
  required DateTime endDate,
  required List<TransactionEntity> transactions,
  required List<ExpenseEntity> expenses,
}) {
  DateTime asDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  bool isInRange(DateTime dt, DateTime start, DateTime end) =>
      !dt.isBefore(start) && !dt.isAfter(end);

  final normalizedStart = asDateOnly(startDate);
  final normalizedEnd = asDateOnly(endDate);

  final filteredTransactions = transactions.where((t) {
    final d = asDateOnly(t.createdAt);
    return isInRange(d, normalizedStart, normalizedEnd);
  }).toList();
  final filteredExpenses = expenses.where((e) {
    final d = asDateOnly(e.expenseDate);
    return isInRange(d, normalizedStart, normalizedEnd);
  }).toList();

  final incomeByDate = <DateTime, double>{};
  final expenseByDate = <DateTime, double>{};

  for (final tx in filteredTransactions) {
    final d = asDateOnly(tx.createdAt);
    incomeByDate[d] = (incomeByDate[d] ?? 0) + tx.totalPrice;
  }
  for (final exp in filteredExpenses) {
    final d = asDateOnly(exp.expenseDate);
    expenseByDate[d] = (expenseByDate[d] ?? 0) + exp.amount;
  }

  final seriesPoints = <ReportSeriesPoint>[];
  var cursor = normalizedStart;
  while (!cursor.isAfter(normalizedEnd)) {
    final income = incomeByDate[cursor] ?? 0;
    final expense = expenseByDate[cursor] ?? 0;
    seriesPoints.add(
      ReportSeriesPoint(
        date: cursor,
        income: income,
        expense: expense,
        netProfit: income - expense,
      ),
    );
    cursor = cursor.add(const Duration(days: 1));
  }

  double totalIncome = 0;
  for (final tx in filteredTransactions) {
    totalIncome += tx.totalPrice;
  }

  double totalExpense = 0;
  for (final exp in filteredExpenses) {
    totalExpense += exp.amount;
  }

  final logs = <ReportLogItem>[];
  if (type == ReportDetailType.income) {
    for (final tx in filteredTransactions) {
      logs.add(
        ReportLogItem(
          date: tx.createdAt,
          title: tx.transactionCode,
          subtitle: tx.customer?.name ?? 'Pelanggan',
          amount: tx.totalPrice,
          kind: ReportLogKind.income,
          referenceId: tx.id,
        ),
      );
    }
  } else if (type == ReportDetailType.expense) {
    for (final exp in filteredExpenses) {
      logs.add(
        ReportLogItem(
          date: exp.expenseDate,
          title: exp.expenseName,
          subtitle: exp.category,
          amount: exp.amount,
          kind: ReportLogKind.expense,
          referenceId: exp.id,
        ),
      );
    }
  } else {
    for (final tx in filteredTransactions) {
      logs.add(
        ReportLogItem(
          date: tx.createdAt,
          title: tx.transactionCode,
          subtitle: tx.customer?.name ?? 'Pemasukan',
          amount: tx.totalPrice,
          kind: ReportLogKind.income,
          referenceId: tx.id,
        ),
      );
    }
    for (final exp in filteredExpenses) {
      logs.add(
        ReportLogItem(
          date: exp.expenseDate,
          title: exp.expenseName,
          subtitle: exp.category,
          amount: exp.amount,
          kind: ReportLogKind.expense,
          referenceId: exp.id,
        ),
      );
    }
  }

  logs.sort((a, b) => b.date.compareTo(a.date));

  final totalAmount = switch (type) {
    ReportDetailType.income => totalIncome,
    ReportDetailType.expense => totalExpense,
    ReportDetailType.netProfit => totalIncome - totalExpense,
  };

  return ReportDetailState(
    type: type,
    startDate: normalizedStart,
    endDate: normalizedEnd,
    seriesPoints: seriesPoints,
    logItems: logs,
    totalAmount: totalAmount,
  );
}
