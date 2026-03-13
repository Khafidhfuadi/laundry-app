import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/features/expenses/domain/entities/expense_entity.dart';
import 'package:laundry_app/features/reports/domain/entities/report_detail.dart';
import 'package:laundry_app/features/reports/presentation/controllers/report_detail_controller.dart';
import 'package:laundry_app/features/transactions/domain/entities/transaction_entity.dart';

void main() {
  group('buildReportDetailState', () {
    test(
      'mengagregasi data harian secara inklusif untuk income/expense/net',
      () {
        final start = DateTime(2026, 3, 1);
        final end = DateTime(2026, 3, 3);

        final transactions = [
          _tx(
            id: 't1',
            code: 'TRX-1',
            date: DateTime(2026, 3, 1, 10),
            total: 10000,
          ),
          _tx(
            id: 't2',
            code: 'TRX-2',
            date: DateTime(2026, 3, 3, 11),
            total: 5000,
          ),
          _tx(
            id: 't3',
            code: 'TRX-3',
            date: DateTime(2026, 3, 4, 9),
            total: 7000,
          ),
        ];
        final expenses = [
          _exp(id: 'e1', date: DateTime(2026, 3, 2, 8), amount: 2000),
          _exp(id: 'e2', date: DateTime(2026, 3, 3, 7), amount: 1000),
          _exp(id: 'e3', date: DateTime(2026, 2, 28, 7), amount: 900),
        ];

        final incomeState = buildReportDetailState(
          type: ReportDetailType.income,
          startDate: start,
          endDate: end,
          transactions: transactions,
          expenses: expenses,
        );
        expect(incomeState.totalAmount, 15000);
        expect(incomeState.seriesPoints.length, 3);
        expect(incomeState.seriesPoints[0].income, 10000);
        expect(incomeState.seriesPoints[1].income, 0);
        expect(incomeState.seriesPoints[2].income, 5000);

        final expenseState = buildReportDetailState(
          type: ReportDetailType.expense,
          startDate: start,
          endDate: end,
          transactions: transactions,
          expenses: expenses,
        );
        expect(expenseState.totalAmount, 3000);
        expect(expenseState.seriesPoints[0].expense, 0);
        expect(expenseState.seriesPoints[1].expense, 2000);
        expect(expenseState.seriesPoints[2].expense, 1000);

        final netState = buildReportDetailState(
          type: ReportDetailType.netProfit,
          startDate: start,
          endDate: end,
          transactions: transactions,
          expenses: expenses,
        );
        expect(netState.totalAmount, 12000);
        expect(netState.seriesPoints[0].netProfit, 10000);
        expect(netState.seriesPoints[1].netProfit, -2000);
        expect(netState.seriesPoints[2].netProfit, 4000);
      },
    );

    test('log net profit menggabungkan income+expense dan terurut terbaru', () {
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 3, 3);

      final transactions = [
        _tx(
          id: 't1',
          code: 'TRX-1',
          date: DateTime(2026, 3, 1, 8),
          total: 3000,
        ),
        _tx(
          id: 't2',
          code: 'TRX-2',
          date: DateTime(2026, 3, 3, 10),
          total: 7000,
        ),
      ];
      final expenses = [
        _exp(id: 'e1', date: DateTime(2026, 3, 3, 12), amount: 2500),
      ];

      final state = buildReportDetailState(
        type: ReportDetailType.netProfit,
        startDate: start,
        endDate: end,
        transactions: transactions,
        expenses: expenses,
      );

      expect(state.logItems.length, 3);
      expect(state.logItems[0].kind, ReportLogKind.expense);
      expect(state.logItems[1].kind, ReportLogKind.income);
      expect(state.logItems[2].kind, ReportLogKind.income);
      expect(state.logItems[0].date.isAfter(state.logItems[1].date), isTrue);
    });

    test('dataset kosong menghasilkan titik nol dan log kosong', () {
      final start = DateTime(2026, 3, 10);
      final end = DateTime(2026, 3, 12);

      final state = buildReportDetailState(
        type: ReportDetailType.income,
        startDate: start,
        endDate: end,
        transactions: const [],
        expenses: const [],
      );

      expect(state.totalAmount, 0);
      expect(state.logItems, isEmpty);
      expect(state.seriesPoints.length, 3);
      expect(state.seriesPoints.every((p) => p.income == 0), isTrue);
      expect(state.seriesPoints.every((p) => p.expense == 0), isTrue);
      expect(state.seriesPoints.every((p) => p.netProfit == 0), isTrue);
    });
  });
}

TransactionEntity _tx({
  required String id,
  required String code,
  required DateTime date,
  required double total,
}) {
  return TransactionEntity(
    id: id,
    transactionCode: code,
    outletId: 'outlet-1',
    customerId: 'customer-1',
    totalPrice: total,
    status: 'PROCESS',
    paymentStatus: 'PAID',
    paidAmount: total,
    notes: '',
    perfumeId: null,
    estimatedCompletionDate: date,
    createdAt: date,
    processedAt: null,
    readyAt: null,
    completedAt: null,
    customer: null,
    outlet: null,
    perfume: null,
    items: const [],
  );
}

ExpenseEntity _exp({
  required String id,
  required DateTime date,
  required double amount,
}) {
  return ExpenseEntity(
    id: id,
    outletId: 'outlet-1',
    expenseName: 'Biaya Operasional',
    category: 'Operasional',
    amount: amount,
    expenseDate: date,
    notes: '',
  );
}
