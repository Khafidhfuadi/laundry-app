class TopServiceSummary {
  final String name;
  final int count;
  final double percentOfMax;

  const TopServiceSummary({
    required this.name,
    required this.count,
    required this.percentOfMax,
  });
}

class ReportSummary {
  // Omset: nilai order saat transaksi dibuat.
  final double totalIncome;
  // Pendapatan: uang yang benar-benar sudah dibayar customer.
  final double totalRevenue;
  final double totalExpense;
  // Laba/Rugi: pendapatan dikurangi pengeluaran.
  final double netProfit;
  // Piutang: sisa tagihan yang belum dibayar.
  final double totalReceivables;
  final int totalTransactions;
  final double incomeChangePercent;
  final double revenueChangePercent;
  final double expenseChangePercent;
  final double netProfitChangePercent;
  final double transactionChangePercent;

  // Indeks 0 = hari paling lama, indeks terakhir = hari ini
  final List<double> dailyIncome;
  final List<double> dailyExpense;

  final List<TopServiceSummary> topServices;
  final Map<String, double> expenseByCategory;

  final int activeCustomers;
  final int newCustomersThisMonth;

  const ReportSummary({
    required this.totalIncome,
    required this.totalRevenue,
    required this.totalExpense,
    required this.netProfit,
    required this.totalReceivables,
    required this.totalTransactions,
    required this.incomeChangePercent,
    required this.revenueChangePercent,
    required this.expenseChangePercent,
    required this.netProfitChangePercent,
    required this.transactionChangePercent,
    required this.dailyIncome,
    required this.dailyExpense,
    required this.topServices,
    required this.expenseByCategory,
    required this.activeCustomers,
    required this.newCustomersThisMonth,
  });

  static ReportSummary empty() {
    return ReportSummary(
      totalIncome: 0,
      totalRevenue: 0,
      totalExpense: 0,
      netProfit: 0,
      totalReceivables: 0,
      totalTransactions: 0,
      incomeChangePercent: 0,
      revenueChangePercent: 0,
      expenseChangePercent: 0,
      netProfitChangePercent: 0,
      transactionChangePercent: 0,
      dailyIncome: List.filled(30, 0.0),
      dailyExpense: List.filled(30, 0.0),
      topServices: [],
      expenseByCategory: {},
      activeCustomers: 0,
      newCustomersThisMonth: 0,
    );
  }
}
