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
      final txFuture = _txDs.getTransactions(outletId: outletId);
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
  double realizedRevenueByPaymentStatus(TransactionEntity transaction) {
    if (transaction.paymentStatus == 'PAID') {
      return transaction.totalPrice;
    }
    if (transaction.paymentStatus == 'PARTIAL') {
      return transaction.paidAmount.clamp(0, transaction.totalPrice);
    }
    return 0;
  }

  DateTime? effectivePaymentDate(TransactionEntity transaction) {
    final realizedRevenue = realizedRevenueByPaymentStatus(transaction);
    if (realizedRevenue <= 0) return null;
    return transaction.paymentReceivedAt ?? transaction.createdAt;
  }

  DateTime asDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  bool isInRange(DateTime dt, DateTime start, DateTime end) =>
      !dt.isBefore(start) && !dt.isAfter(end);

  final normalizedStart = asDateOnly(startDate);
  final normalizedEnd = asDateOnly(endDate);

  final filteredOmsetTransactions = transactions.where((t) {
    final d = asDateOnly(t.createdAt);
    return isInRange(d, normalizedStart, normalizedEnd);
  }).toList();
  final filteredRevenueTransactions = transactions.where((t) {
    final paymentDate = effectivePaymentDate(t);
    if (paymentDate == null) return false;
    final d = asDateOnly(paymentDate);
    return isInRange(d, normalizedStart, normalizedEnd);
  }).toList();
  final filteredExpenses = expenses.where((e) {
    final d = asDateOnly(e.expenseDate);
    return isInRange(d, normalizedStart, normalizedEnd);
  }).toList();

  final turnoverByDate = <DateTime, double>{};
  final incomeByDate = <DateTime, double>{};
  final expenseByDate = <DateTime, double>{};

  for (final tx in filteredOmsetTransactions) {
    final d = asDateOnly(tx.createdAt);
    turnoverByDate[d] = (turnoverByDate[d] ?? 0) + tx.totalPrice;
  }
  for (final tx in filteredRevenueTransactions) {
    final paymentDate = effectivePaymentDate(tx);
    if (paymentDate == null) continue;
    final d = asDateOnly(paymentDate);
    incomeByDate[d] =
        (incomeByDate[d] ?? 0) + realizedRevenueByPaymentStatus(tx);
  }
  for (final exp in filteredExpenses) {
    final d = asDateOnly(exp.expenseDate);
    expenseByDate[d] = (expenseByDate[d] ?? 0) + exp.amount;
  }

  final seriesPoints = <ReportSeriesPoint>[];
  var cursor = normalizedStart;
  while (!cursor.isAfter(normalizedEnd)) {
    final turnover = turnoverByDate[cursor] ?? 0;
    final income = incomeByDate[cursor] ?? 0;
    final expense = expenseByDate[cursor] ?? 0;
    seriesPoints.add(
      ReportSeriesPoint(
        date: cursor,
        turnover: turnover,
        income: income,
        expense: expense,
        netProfit: income - expense,
      ),
    );
    cursor = cursor.add(const Duration(days: 1));
  }

  double totalTurnover = 0;
  for (final tx in filteredOmsetTransactions) {
    totalTurnover += tx.totalPrice;
  }

  double totalIncome = 0;
  for (final tx in filteredRevenueTransactions) {
    totalIncome += realizedRevenueByPaymentStatus(tx);
  }

  double totalExpense = 0;
  for (final exp in filteredExpenses) {
    totalExpense += exp.amount;
  }

  final logs = <ReportLogItem>[];
  if (type == ReportDetailType.turnover) {
    for (final tx in filteredOmsetTransactions) {
      logs.add(
        ReportLogItem(
          date: tx.createdAt,
          title: tx.transactionCode,
          subtitle: tx.customer?.name ?? 'Order customer',
          amount: tx.totalPrice,
          kind: ReportLogKind.income,
          referenceId: tx.id,
        ),
      );
    }
  } else if (type == ReportDetailType.income) {
    for (final tx in filteredRevenueTransactions) {
      final paymentDate = effectivePaymentDate(tx);
      if (paymentDate == null) continue;
      final realizedRevenue = realizedRevenueByPaymentStatus(tx);
      if (realizedRevenue <= 0) continue;
      logs.add(
        ReportLogItem(
          date: paymentDate,
          title: tx.transactionCode,
          subtitle: tx.customer?.name ?? 'Pembayaran customer',
          amount: realizedRevenue,
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
    for (final tx in filteredRevenueTransactions) {
      final paymentDate = effectivePaymentDate(tx);
      if (paymentDate == null) continue;
      final realizedRevenue = realizedRevenueByPaymentStatus(tx);
      if (realizedRevenue <= 0) continue;
      logs.add(
        ReportLogItem(
          date: paymentDate,
          title: tx.transactionCode,
          subtitle: tx.customer?.name ?? 'Pemasukan',
          amount: realizedRevenue,
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
    ReportDetailType.turnover => totalTurnover,
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
