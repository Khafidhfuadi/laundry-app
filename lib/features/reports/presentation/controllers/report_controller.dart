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
enum ReportPeriod { today, yesterday, last7Days, custom }

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

  bool _isCancelledStatus(String status) {
    return status == 'CANCELLED' || status == 'CANCELED';
  }

  double _paymentInflowAmount(TransactionEntity transaction) {
    return transaction.paidAmount.clamp(0, transaction.totalPrice);
  }

  double _refundOutflowAmount(TransactionEntity transaction) {
    final inflow = _paymentInflowAmount(transaction);
    return transaction.refundAmount.clamp(0, inflow);
  }

  DateTime? _effectivePaymentDate(TransactionEntity transaction) {
    final paymentInflow = _paymentInflowAmount(transaction);
    if (paymentInflow <= 0) return null;
    return transaction.paymentReceivedAt ?? transaction.createdAt;
  }

  DateTime? _effectiveRefundDate(TransactionEntity transaction) {
    final refund = _refundOutflowAmount(transaction);
    if (refund <= 0) return null;
    return transaction.refundAt ?? transaction.createdAt;
  }

  @override
  FutureOr<ReportSummary> build() async {
    _txDs = ref.watch(_reportTransactionDatasourceProvider);
    _expDs = ref.watch(_reportExpenseDatasourceProvider);
    // Tidak memuat data secara otomatis; loadReport() dipanggil dari UI
    // setelah outlet_id diketahui.
    return ReportSummary.empty();
  }

  /// Memuat laporan berdasarkan custom date range (untuk mode Kustom).
  Future<void> loadReportWithRange(
    String outletId,
    DateTime customStart,
    DateTime customEnd,
  ) async {
    final daysBack = customEnd.difference(customStart).inDays + 1;
    final previousEnd = customStart.subtract(const Duration(days: 1));
    final previousStart =
        previousEnd.subtract(Duration(days: daysBack - 1));
    await _loadReportInternal(
      outletId: outletId,
      currentStartDate: customStart,
      currentEndDate: customEnd,
      previousStartDate: previousStart,
      previousEndDate: previousEnd,
      daysBack: daysBack,
    );
  }

  Future<void> loadReport(String outletId, ReportPeriod period) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    late DateTime currentStartDate;
    final currentEndDate = today;
    late DateTime previousStartDate;
    late DateTime previousEndDate;
    int daysBack;

    if (period == ReportPeriod.today) {
      daysBack = 1;
      currentStartDate = today;
      previousEndDate = today.subtract(const Duration(days: 1));
      previousStartDate = previousEndDate;
    } else if (period == ReportPeriod.yesterday) {
      daysBack = 1;
      currentStartDate = today.subtract(const Duration(days: 1));
      previousEndDate = today.subtract(const Duration(days: 2));
      previousStartDate = previousEndDate;
    } else {
      // last7Days (default)
      daysBack = 7;
      currentStartDate = today.subtract(const Duration(days: 6));
      previousEndDate = currentStartDate.subtract(const Duration(days: 1));
      previousStartDate = previousEndDate.subtract(const Duration(days: 6));
    }

    await _loadReportInternal(
      outletId: outletId,
      currentStartDate: currentStartDate,
      currentEndDate: currentEndDate,
      previousStartDate: previousStartDate,
      previousEndDate: previousEndDate,
      daysBack: daysBack,
    );
  }

  Future<void> _loadReportInternal({
    required String outletId,
    required DateTime currentStartDate,
    required DateTime currentEndDate,
    required DateTime previousStartDate,
    required DateTime previousEndDate,
    required int daysBack,
  }) async {
    state = const AsyncValue.loading();
    try {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

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
      final omsetTransactions = allTransactions.where((t) {
        if (_isCancelledStatus(t.status)) return false;
        final d = asDateOnly(t.createdAt);
        return isInRange(d, currentStartDate, currentEndDate);
      }).toList();
      final revenueTransactions = allTransactions.where((t) {
        final paymentDate = _effectivePaymentDate(t);
        if (paymentDate == null) return false;
        final d = asDateOnly(paymentDate);
        return isInRange(d, currentStartDate, currentEndDate);
      }).toList();
      final refundTransactions = allTransactions.where((t) {
        final refundDate = _effectiveRefundDate(t);
        if (refundDate == null) return false;
        final d = asDateOnly(refundDate);
        return isInRange(d, currentStartDate, currentEndDate);
      }).toList();
      final expenses = allExpenses.where((e) {
        final d = asDateOnly(e.expenseDate);
        return isInRange(d, currentStartDate, currentEndDate);
      }).toList();

      // Filter data periode sebelumnya untuk pembanding
      final previousOmsetTransactions = allTransactions.where((t) {
        if (_isCancelledStatus(t.status)) return false;
        final d = asDateOnly(t.createdAt);
        return isInRange(d, previousStartDate, previousEndDate);
      }).toList();
      final previousRevenueTransactions = allTransactions.where((t) {
        final paymentDate = _effectivePaymentDate(t);
        if (paymentDate == null) return false;
        final d = asDateOnly(paymentDate);
        return isInRange(d, previousStartDate, previousEndDate);
      }).toList();
      final previousRefundTransactions = allTransactions.where((t) {
        final refundDate = _effectiveRefundDate(t);
        if (refundDate == null) return false;
        final d = asDateOnly(refundDate);
        return isInRange(d, previousStartDate, previousEndDate);
      }).toList();
      final previousExpenses = allExpenses.where((e) {
        final d = asDateOnly(e.expenseDate);
        return isInRange(d, previousStartDate, previousEndDate);
      }).toList();

      // --- Ringkasan omset + pendapatan ---
      double totalIncome = 0;
      double totalRevenue = 0;
      double totalReceivables = 0;
      for (final t in omsetTransactions) {
        totalIncome += t.totalPrice;
        final paymentInflow = _paymentInflowAmount(t);
        totalReceivables += (t.totalPrice - paymentInflow).clamp(
          0,
          double.infinity,
        );
      }
      for (final t in revenueTransactions) {
        totalRevenue += _paymentInflowAmount(t);
      }
      for (final t in refundTransactions) {
        totalRevenue -= _refundOutflowAmount(t);
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
      double previousRevenue = 0;
      for (final t in previousOmsetTransactions) {
        previousIncome += t.totalPrice;
      }
      for (final t in previousRevenueTransactions) {
        previousRevenue += _paymentInflowAmount(t);
      }
      for (final t in previousRefundTransactions) {
        previousRevenue -= _refundOutflowAmount(t);
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
      final revenueChangePercent = pctChange(totalRevenue, previousRevenue);
      final expenseChangePercent = pctChange(totalExpense, previousExpense);
      final netProfitChangePercent = pctChange(
        totalRevenue - totalExpense,
        previousRevenue - previousExpense,
      );
      final transactionChangePercent = pctChange(
        omsetTransactions.length,
        previousOmsetTransactions.length,
      );

      // --- Daily arrays (panjang = daysBack, indeks 0 = hari paling lama) ---
      final dailyIncome = List<double>.filled(daysBack, 0.0);
      final dailyExpense = List<double>.filled(daysBack, 0.0);

      for (final t in revenueTransactions) {
        final paymentDate = _effectivePaymentDate(t);
        if (paymentDate == null) continue;
        final trxDay = asDateOnly(paymentDate);
        final diff = today.difference(trxDay).inDays;
        if (diff >= 0 && diff < daysBack) {
          final inflow = _paymentInflowAmount(t);
          dailyIncome[(daysBack - 1) - diff] += inflow / 1000;
        }
      }
      for (final t in refundTransactions) {
        final refundDate = _effectiveRefundDate(t);
        if (refundDate == null) continue;
        final refundDay = asDateOnly(refundDate);
        final diff = today.difference(refundDay).inDays;
        if (diff >= 0 && diff < daysBack) {
          final refund = _refundOutflowAmount(t);
          dailyIncome[(daysBack - 1) - diff] -= refund / 1000;
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
      for (final t in omsetTransactions) {
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
      final activeCustomerIds = omsetTransactions
          .map((t) => t.customerId)
          .toSet();
      final nowForMonth = DateTime.now();
      final startOfMonth = DateTime(nowForMonth.year, nowForMonth.month, 1);
      final newCustomerIds = omsetTransactions
          .where((t) => !t.createdAt.isBefore(startOfMonth))
          .map((t) => t.customerId)
          .toSet();

      state = AsyncValue.data(
        ReportSummary(
          totalIncome: totalIncome,
          totalRevenue: totalRevenue,
          totalExpense: totalExpense,
          netProfit: totalRevenue - totalExpense,
          totalReceivables: totalReceivables,
          totalTransactions: omsetTransactions.length,
          incomeChangePercent: incomeChangePercent,
          revenueChangePercent: revenueChangePercent,
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
