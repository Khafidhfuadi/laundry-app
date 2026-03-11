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
  final double totalIncome;
  final double totalExpense;
  final double netProfit;
  final int totalTransactions;

  // Indeks 0 = hari paling lama, indeks terakhir = hari ini
  final List<double> dailyIncome;
  final List<double> dailyExpense;

  final List<TopServiceSummary> topServices;
  final Map<String, double> expenseByCategory;

  final int activeCustomers;
  final int newCustomersThisMonth;

  const ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
    required this.totalTransactions,
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
      totalExpense: 0,
      netProfit: 0,
      totalTransactions: 0,
      dailyIncome: List.filled(30, 0.0),
      dailyExpense: List.filled(30, 0.0),
      topServices: [],
      expenseByCategory: {},
      activeCustomers: 0,
      newCustomersThisMonth: 0,
    );
  }
}
