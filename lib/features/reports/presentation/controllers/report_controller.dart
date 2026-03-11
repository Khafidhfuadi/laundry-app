import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/datasources/transaction_remote_datasource.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../expenses/data/datasources/expense_remote_datasource.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../domain/entities/report_summary.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _reportTransactionDatasourceProvider =
    Provider<TransactionRemoteDatasource>((ref) {
  return TransactionRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
});

final _reportExpenseDatasourceProvider =
    Provider<ExpenseRemoteDatasource>((ref) {
  return ExpenseRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
});

/// Filter period yang tersedia di halaman laporan.
enum ReportPeriod { thisWeek, thisMonth, thisYear }




final reportControllerProvider =
    AsyncNotifierProvider<ReportController, ReportSummary>(
  ReportController.new,
);

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class ReportController extends AsyncNotifier<ReportSummary> {
  late TransactionRemoteDatasource _txDs;
  late ExpenseRemoteDatasource _expDs;

  @override
  FutureOr<ReportSummary> build() async {
    _txDs = ref.watch(_reportTransactionDatasourceProvider);
    _expDs = ref.watch(_reportExpenseDatasourceProvider);
    // Tidak memuat data secara otomatis; loadReport() dipanggil dari UI
    // setelah outlet_id diketahui.
    return ReportSummary.empty();
  }

  Future<void> loadReport(String outletId, ReportPeriod period) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Tentukan rentang tanggal berdasarkan period
      late DateTime startDate;
      int daysBack;
      if (period == ReportPeriod.thisWeek) {
        daysBack = 7;
        startDate = today.subtract(const Duration(days: 6));
      } else if (period == ReportPeriod.thisYear) {
        daysBack = 365;
        startDate = DateTime(now.year, 1, 1);
      } else {
        // thisMonth
        daysBack = 30;
        startDate = DateTime(now.year, now.month, 1);
      }

      // Ambil data dari Supabase secara paralel
      final txFuture = _txDs.getTransactions(outletId: outletId);
      final expFuture = _expDs.getExpenses(
        outletId: outletId,
        startDate: startDate,
      );

      final results = await Future.wait([txFuture, expFuture]);
      final allTransactions = results[0] as List<TransactionEntity>;
      final expenses = results[1] as List<ExpenseEntity>;

      // Filter transaksi sesuai periode
      final transactions = allTransactions
          .where((t) => !t.createdAt.isBefore(startDate))
          .toList();

      // --- Ringkasan income ---
      double totalIncome = 0;
      for (final t in transactions) {
        totalIncome += t.totalPrice;
      }

      // --- Ringkasan expense ---
      double totalExpense = 0;
      final Map<String, double> expenseByCategory = {};
      for (final e in expenses) {
        totalExpense += e.amount;
        expenseByCategory[e.category] =
            (expenseByCategory[e.category] ?? 0) + e.amount;
      }

      // --- Daily arrays (panjang = daysBack, indeks 0 = hari paling lama) ---
      final dailyIncome = List<double>.filled(daysBack, 0.0);
      final dailyExpense = List<double>.filled(daysBack, 0.0);

      for (final t in transactions) {
        final trxDay =
            DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
        final diff = today.difference(trxDay).inDays;
        if (diff >= 0 && diff < daysBack) {
          dailyIncome[(daysBack - 1) - diff] += t.totalPrice / 1000;
        }
      }
      for (final e in expenses) {
        final expDay = DateTime(
            e.expenseDate.year, e.expenseDate.month, e.expenseDate.day);
        final diff = today.difference(expDay).inDays;
        if (diff >= 0 && diff < daysBack) {
          dailyExpense[(daysBack - 1) - diff] += e.amount / 1000;
        }
      }

      // --- Top services ---
      final Map<String, int> serviceCount = {};
      for (final t in transactions) {
        for (final item in t.items) {
          final name = item.service?.fullName ?? 'Layanan';
          serviceCount[name] = (serviceCount[name] ?? 0) + 1;
        }
      }
      final sortedEntries = serviceCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final maxCount =
          sortedEntries.isNotEmpty ? sortedEntries.first.value : 1;
      final topServices = sortedEntries
          .take(5)
          .map(
            (e) => TopServiceSummary(
              name: e.key,
              count: e.value,
              percentOfMax: e.value / maxCount,
            ),
          )
          .toList();

      // --- Customer stats ---
      final activeCustomerIds = transactions.map((t) => t.customerId).toSet();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final newCustomerIds = transactions
          .where((t) => !t.createdAt.isBefore(startOfMonth))
          .map((t) => t.customerId)
          .toSet();

      state = AsyncValue.data(
        ReportSummary(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          netProfit: totalIncome - totalExpense,
          totalTransactions: transactions.length,
          dailyIncome: dailyIncome,
          dailyExpense: dailyExpense,
          topServices: topServices,
          expenseByCategory: expenseByCategory,
          activeCustomers: activeCustomerIds.length,
          newCustomersThisMonth: newCustomerIds.length,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
