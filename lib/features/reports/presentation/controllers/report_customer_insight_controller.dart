import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../transactions/data/datasources/transaction_remote_datasource.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

class CustomerInsightItem {
  final String customerId;
  final String customerName;
  final int transactionCount;
  final double totalOmset;
  final double totalPendapatan;
  final DateTime lastTransactionDate;

  const CustomerInsightItem({
    required this.customerId,
    required this.customerName,
    required this.transactionCount,
    required this.totalOmset,
    required this.totalPendapatan,
    required this.lastTransactionDate,
  });
}

class ReportCustomerInsightState {
  final DateTime startDate;
  final DateTime endDate;
  final int activeCustomers;
  final int newCustomers;
  final int totalTransactions;
  final List<CustomerInsightItem> customers;

  const ReportCustomerInsightState({
    required this.startDate,
    required this.endDate,
    required this.activeCustomers,
    required this.newCustomers,
    required this.totalTransactions,
    required this.customers,
  });

  factory ReportCustomerInsightState.empty() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ReportCustomerInsightState(
      startDate: today,
      endDate: today,
      activeCustomers: 0,
      newCustomers: 0,
      totalTransactions: 0,
      customers: const [],
    );
  }
}

final _reportCustomerInsightDatasourceProvider =
    Provider<TransactionRemoteDatasource>((ref) {
      return TransactionRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
    });

final reportCustomerInsightControllerProvider =
    AsyncNotifierProvider<
      ReportCustomerInsightController,
      ReportCustomerInsightState
    >(ReportCustomerInsightController.new);

class ReportCustomerInsightController
    extends AsyncNotifier<ReportCustomerInsightState> {
  late TransactionRemoteDatasource _txDs;

  @override
  FutureOr<ReportCustomerInsightState> build() async {
    _txDs = ref.watch(_reportCustomerInsightDatasourceProvider);
    return ReportCustomerInsightState.empty();
  }

  DateTime _asDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isInRange(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  double _realizedRevenueByPaymentStatus(TransactionEntity transaction) {
    if (transaction.paymentStatus == 'PAID') {
      return transaction.totalPrice;
    }
    if (transaction.paymentStatus == 'PARTIAL') {
      return transaction.paidAmount.clamp(0, transaction.totalPrice);
    }
    return 0;
  }

  Future<void> loadInsight({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final normalizedStart = _asDateOnly(startDate);
      final normalizedEnd = _asDateOnly(endDate);

      final allTransactions = await _txDs.getTransactions(outletId: outletId);

      final transactionsInRange = allTransactions.where((tx) {
        final d = _asDateOnly(tx.createdAt);
        return _isInRange(d, normalizedStart, normalizedEnd);
      }).toList();

      final firstOrderByCustomer = <String, DateTime>{};
      for (final tx in allTransactions) {
        final existing = firstOrderByCustomer[tx.customerId];
        if (existing == null || tx.createdAt.isBefore(existing)) {
          firstOrderByCustomer[tx.customerId] = tx.createdAt;
        }
      }

      final statsByCustomer =
          <
            String,
            ({
              String name,
              int count,
              double omset,
              double pendapatan,
              DateTime lastDate,
            })
          >{};

      for (final tx in transactionsInRange) {
        final current = statsByCustomer[tx.customerId];
        final nextPendapatan = _realizedRevenueByPaymentStatus(tx);
        final customerName = tx.customer?.name ?? 'Pelanggan';

        if (current == null) {
          statsByCustomer[tx.customerId] = (
            name: customerName,
            count: 1,
            omset: tx.totalPrice,
            pendapatan: nextPendapatan,
            lastDate: tx.createdAt,
          );
        } else {
          statsByCustomer[tx.customerId] = (
            name: current.name,
            count: current.count + 1,
            omset: current.omset + tx.totalPrice,
            pendapatan: current.pendapatan + nextPendapatan,
            lastDate: tx.createdAt.isAfter(current.lastDate)
                ? tx.createdAt
                : current.lastDate,
          );
        }
      }

      final customers =
          statsByCustomer.entries
              .map(
                (entry) => CustomerInsightItem(
                  customerId: entry.key,
                  customerName: entry.value.name,
                  transactionCount: entry.value.count,
                  totalOmset: entry.value.omset,
                  totalPendapatan: entry.value.pendapatan,
                  lastTransactionDate: entry.value.lastDate,
                ),
              )
              .toList()
            ..sort((a, b) => b.totalOmset.compareTo(a.totalOmset));

      final activeCustomerIds = statsByCustomer.keys.toSet();
      final newCustomers = activeCustomerIds.where((customerId) {
        final firstOrder = firstOrderByCustomer[customerId];
        if (firstOrder == null) return false;
        final firstDate = _asDateOnly(firstOrder);
        return _isInRange(firstDate, normalizedStart, normalizedEnd);
      }).length;

      state = AsyncValue.data(
        ReportCustomerInsightState(
          startDate: normalizedStart,
          endDate: normalizedEnd,
          activeCustomers: activeCustomerIds.length,
          newCustomers: newCustomers,
          totalTransactions: transactionsInRange.length,
          customers: customers,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
