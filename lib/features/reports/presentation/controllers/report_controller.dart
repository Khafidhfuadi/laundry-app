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

final _reportExpenseDatasourceProvider = Provider<ExpenseRemoteDatasource>((
  ref,
) {
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

      // Tentukan rentang tanggal saat ini + periode pembanding sebelumnya
      late DateTime currentStartDate;
      final currentEndDate = today;
      late DateTime previousStartDate;
      late DateTime previousEndDate;
      int daysBack;

      if (period == ReportPeriod.thisWeek) {
        daysBack = 7;
        currentStartDate = today.subtract(const Duration(days: 6));
        previousEndDate = currentStartDate.subtract(const Duration(days: 1));
        previousStartDate = previousEndDate.subtract(const Duration(days: 6));
      } else if (period == ReportPeriod.thisYear) {
        currentStartDate = DateTime(now.year, 1, 1);
        daysBack = today.difference(currentStartDate).inDays + 1;
        previousStartDate = DateTime(now.year - 1, 1, 1);
        previousEndDate = previousStartDate.add(Duration(days: daysBack - 1));
      } else {
        // thisMonth
        currentStartDate = DateTime(now.year, now.month, 1);
        daysBack = today.difference(currentStartDate).inDays + 1;
        previousStartDate = DateTime(now.year, now.month - 1, 1);
        final previousMonthLastDay = DateTime(now.year, now.month, 0);
        final idealPreviousEnd = previousStartDate.add(
          Duration(days: daysBack - 1),
        );
        previousEndDate = idealPreviousEnd.isAfter(previousMonthLastDay)
            ? previousMonthLastDay
            : idealPreviousEnd;
      }

      // Ambil data dari Supabase secara paralel
      final txFuture = _txDs.getTransactions(outletId: outletId);
      final expFuture = _expDs.getExpenses(outletId: outletId);

      final results = await Future.wait([txFuture, expFuture]);
      final allTransactions = results[0] as List<TransactionEntity>;
      final allExpenses = results[1] as List<ExpenseEntity>;

      DateTime asDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

      bool isInRange(DateTime date, DateTime start, DateTime end) {
        return !date.isBefore(start) && !date.isAfter(end);
      }

      // Filter data periode saat ini
      final transactions = allTransactions.where((t) {
        final d = asDateOnly(t.createdAt);
        return isInRange(d, currentStartDate, currentEndDate);
      }).toList();
      final expenses = allExpenses.where((e) {
        final d = asDateOnly(e.expenseDate);
        return isInRange(d, currentStartDate, currentEndDate);
      }).toList();

      // Filter data periode sebelumnya untuk pembanding
      final previousTransactions = allTransactions.where((t) {
        final d = asDateOnly(t.createdAt);
        return isInRange(d, previousStartDate, previousEndDate);
      }).toList();
      final previousExpenses = allExpenses.where((e) {
        final d = asDateOnly(e.expenseDate);
        return isInRange(d, previousStartDate, previousEndDate);
      }).toList();

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

      // --- Ringkasan pembanding ---
      double previousIncome = 0;
      for (final t in previousTransactions) {
        previousIncome += t.totalPrice;
      }
      double previousExpense = 0;
      for (final e in previousExpenses) {
        previousExpense += e.amount;
      }

      double pctChange(num current, num previous) {
        if (previous == 0) {
          return current == 0 ? 0 : 100;
        }
        return ((current - previous) / previous) * 100;
      }

      final incomeChangePercent = pctChange(totalIncome, previousIncome);
      final expenseChangePercent = pctChange(totalExpense, previousExpense);
      final netProfitChangePercent = pctChange(
        totalIncome - totalExpense,
        previousIncome - previousExpense,
      );
      final transactionChangePercent = pctChange(
        transactions.length,
        previousTransactions.length,
      );

      // --- Daily arrays (panjang = daysBack, indeks 0 = hari paling lama) ---
      final dailyIncome = List<double>.filled(daysBack, 0.0);
      final dailyExpense = List<double>.filled(daysBack, 0.0);

      for (final t in transactions) {
        final trxDay = asDateOnly(t.createdAt);
        final diff = today.difference(trxDay).inDays;
        if (diff >= 0 && diff < daysBack) {
          dailyIncome[(daysBack - 1) - diff] += t.totalPrice / 1000;
        }
      }
      for (final e in expenses) {
        final expDay = asDateOnly(e.expenseDate);
        final diff = today.difference(expDay).inDays;
        if (diff >= 0 && diff < daysBack) {
          dailyExpense[(daysBack - 1) - diff] += e.amount / 1000;
        }
      }

      // --- Top services ---
      final Map<String, int> serviceCount = {};
      for (final t in transactions) {
        for (final item in t.items) {
          final name = item.serviceVariant?.service?.name ?? 'Layanan';
          serviceCount[name] = (serviceCount[name] ?? 0) + 1;
        }
      }
      final sortedEntries = serviceCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final maxCount = sortedEntries.isNotEmpty ? sortedEntries.first.value : 1;
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
          incomeChangePercent: incomeChangePercent,
          expenseChangePercent: expenseChangePercent,
          netProfitChangePercent: netProfitChangePercent,
          transactionChangePercent: transactionChangePercent,
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
