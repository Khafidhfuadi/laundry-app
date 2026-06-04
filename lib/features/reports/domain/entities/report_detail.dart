enum ReportDetailType { turnover, income, expense, netProfit }

enum ReportDetailRangePreset { today, yesterday, last7Days, custom }

enum ReportLogKind { income, expense }

class ReportSeriesPoint {
  final DateTime date;
  final double turnover;
  final double income;
  final double expense;
  final double netProfit;

  const ReportSeriesPoint({
    required this.date,
    required this.turnover,
    required this.income,
    required this.expense,
    required this.netProfit,
  });
}

class ReportLogItem {
  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final ReportLogKind kind;
  final String? referenceId;

  const ReportLogItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.kind,
    this.referenceId,
  });
}

class ReportDetailState {
  final ReportDetailType type;
  final DateTime startDate;
  final DateTime endDate;
  final List<ReportSeriesPoint> seriesPoints;
  final List<ReportLogItem> logItems;
  final double totalAmount;

  const ReportDetailState({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.seriesPoints,
    required this.logItems,
    required this.totalAmount,
  });

  factory ReportDetailState.empty() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ReportDetailState(
      type: ReportDetailType.turnover,
      startDate: today,
      endDate: today,
      seriesPoints: const [],
      logItems: const [],
      totalAmount: 0,
    );
  }
}
