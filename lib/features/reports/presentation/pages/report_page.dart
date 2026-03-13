import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/custom_bottom_nav.dart';
import '../../../outlet/presentation/controllers/active_outlet_controller.dart';
import '../controllers/report_controller.dart';
import '../../domain/entities/report_summary.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  ReportPeriod _selectedPeriod = ReportPeriod.thisWeek;

  final _periodLabels = {
    ReportPeriod.thisWeek: 'Minggu Ini',
    ReportPeriod.thisMonth: 'Bulan Ini',
    ReportPeriod.thisYear: 'Tahun Ini',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  void _loadReport() {
    final outletState = ref.read(activeOutletProvider);
    final outletId = outletState.value?.id ?? '';
    if (outletId.isNotEmpty) {
      ref
          .read(reportControllerProvider.notifier)
          .loadReport(outletId, _selectedPeriod);
    }
  }

  void _switchPeriod(ReportPeriod period) {
    setState(() => _selectedPeriod = period);
    final outletState = ref.read(activeOutletProvider);
    final outletId = outletState.value?.id ?? '';
    if (outletId.isNotEmpty) {
      ref.read(reportControllerProvider.notifier).loadReport(outletId, period);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: reportState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat laporan:\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReport,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
          data: (summary) => RefreshIndicator(
            onRefresh: () async => _loadReport(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  _buildFilterChips(),
                  _buildSummaryGrid(summary),
                  _buildDetailReportsListSection(context),
                  _buildBarChartSection(summary),
                  _buildTopServicesSection(summary),
                  _buildCustomerStatsSection(summary),
                  if (summary.expenseByCategory.isNotEmpty)
                    _buildDonutChartSection(summary),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: const CustomBottomNavFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  // -------------------------------------------------------------------------
  // App Bar
  // -------------------------------------------------------------------------
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F62FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Laporan & Statistik',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF0F62FE),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filter Chips
  // -------------------------------------------------------------------------
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: _periodLabels.entries.map((entry) {
          final isSelected = _selectedPeriod == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _switchPeriod(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0F62FE)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Summary Grid (Kartu Keuangan)
  // -------------------------------------------------------------------------
  Widget _buildSummaryGrid(ReportSummary summary) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final comparisonLabel = _comparisonBaselineLabel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            'Total Pemasukan',
            fmt.format(summary.totalIncome),
            true,
            false,
            changePercent: summary.incomeChangePercent,
            baselineLabel: comparisonLabel,
          ),
          _buildStatCard(
            'Pengeluaran',
            fmt.format(summary.totalExpense),
            false,
            true,
            changePercent: summary.expenseChangePercent,
            baselineLabel: comparisonLabel,
          ),
          _buildStatCard(
            'Laba Bersih',
            fmt.format(summary.netProfit),
            summary.netProfit >= 0,
            false,
            highlightValue: true,
            changePercent: summary.netProfitChangePercent,
            baselineLabel: comparisonLabel,
          ),
          _buildStatCard(
            'Transaksi',
            summary.totalTransactions.toString(),
            true,
            false,
            changePercent: summary.transactionChangePercent,
            baselineLabel: comparisonLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    bool isPositive,
    bool isExpense, {
    bool highlightValue = false,
    required double changePercent,
    required String baselineLabel,
  }) {
    final isChangePositive = changePercent >= 0;
    final sign = isChangePositive ? '+' : '';
    final changeLabel = '$sign${changePercent.toStringAsFixed(1)}%';

    final trendColor = isExpense
        ? (isChangePositive ? const Color(0xFFEF4444) : const Color(0xFF10B981))
        : (isChangePositive
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlightValue
                  ? const Color(0xFF0F62FE)
                  : const Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isChangePositive ? Icons.trending_up : Icons.trending_down,
                color: trendColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                changeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'vs $baselineLabel',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Detail Report List
  // -------------------------------------------------------------------------
  Widget _buildDetailReportsListSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Laporan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailReportTile(
            icon: Icons.trending_up,
            title: 'Laporan Pemasukan',
            subtitle: 'Grafik dan log pemasukan',
            iconColor: const Color(0xFF0F62FE),
            iconBgColor: const Color(0xFFDBEAFE),
            onTap: () => context.push('/reports/income'),
          ),
          _buildDetailReportTile(
            icon: Icons.trending_down,
            title: 'Laporan Pengeluaran',
            subtitle: 'Grafik dan log pengeluaran',
            iconColor: const Color(0xFFEF4444),
            iconBgColor: const Color(0xFFFEE2E2),
            onTap: () => context.push('/reports/expense'),
          ),
          _buildDetailReportTile(
            icon: Icons.show_chart,
            title: 'Laporan Laba Bersih',
            subtitle: 'Grafik dan log laba bersih',
            iconColor: const Color(0xFF10B981),
            iconBgColor: const Color(0xFFD1FAE5),
            onTap: () => context.push('/reports/net-profit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailReportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Bar Chart
  // -------------------------------------------------------------------------
  Widget _buildBarChartSection(ReportSummary summary) {
    final daysCount = summary.dailyIncome.length;
    final maxIncome = summary.dailyIncome.isNotEmpty
        ? summary.dailyIncome.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final maxExpense = summary.dailyExpense.isNotEmpty
        ? summary.dailyExpense.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final maxY = (maxIncome > maxExpense ? maxIncome : maxExpense) * 1.2;
    final effectiveMaxY = maxY < 5 ? 20.0 : maxY;

    // Tampilkan maksimal 30 batang (atau sesuai daysCount)
    final displayCount = daysCount > 30 ? 30 : daysCount;
    final startOffset = daysCount - displayCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tren Keuangan (${_periodLabels[_selectedPeriod] ?? "Periode Ini"})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _buildLegendIndicator(const Color(0xFF0F62FE), 'Masuk'),
                  const SizedBox(width: 12),
                  _buildLegendIndicator(const Color(0xFFFDA4AF), 'Keluar'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: effectiveMaxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final bottomInterval = displayCount <= 8
                            ? 1
                            : (displayCount / 6).ceil();
                        final index = value.toInt();
                        if (index < 0 || index >= displayCount) {
                          return const SizedBox.shrink();
                        }
                        if (index % bottomInterval != 0 &&
                            index != displayCount - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _buildTrendDateLabel(
                              startOffset + index,
                              daysCount,
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(displayCount, (i) {
                  final income = summary.dailyIncome[startOffset + i];
                  final expense = summary.dailyExpense[startOffset + i];
                  return _makeGroupData(i, income, expense);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  String _buildTrendDateLabel(int indexInPeriod, int totalDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: totalDays - 1));
    final date = startDate.add(Duration(days: indexInPeriod));

    if (_selectedPeriod == ReportPeriod.thisWeek) {
      return DateFormat('EEE', 'id_ID').format(date);
    }
    if (_selectedPeriod == ReportPeriod.thisMonth) {
      return DateFormat('d MMM', 'id_ID').format(date);
    }
    return DateFormat('d/M', 'id_ID').format(date);
  }

  String _comparisonBaselineLabel() {
    if (_selectedPeriod == ReportPeriod.thisWeek) return 'minggu lalu';
    if (_selectedPeriod == ReportPeriod.thisMonth) return 'bulan lalu';
    return 'tahun lalu';
  }

  BarChartGroupData _makeGroupData(int x, double income, double expense) {
    return BarChartGroupData(
      x: x,
      barsSpace: 3,
      barRods: [
        BarChartRodData(
          toY: income < 0.01 ? 0 : income,
          width: 6,
          borderRadius: BorderRadius.circular(3),
          color: const Color(0xFF0F62FE),
        ),
        BarChartRodData(
          toY: expense < 0.01 ? 0 : expense,
          width: 6,
          borderRadius: BorderRadius.circular(3),
          color: const Color(0xFFFDA4AF),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Top Services
  // -------------------------------------------------------------------------
  Widget _buildTopServicesSection(ReportSummary summary) {
    if (summary.topServices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan Terlaris',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...summary.topServices.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTopServiceItem(
                s.name,
                '${s.count} Pesanan',
                s.percentOfMax,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServiceItem(String name, String count, double percent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: const Color(0xFFEEF2FF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F62FE)),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Customer Stats
  // -------------------------------------------------------------------------
  Widget _buildCustomerStatsSection(ReportSummary summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildClientStatCard(
              Icons.people,
              summary.activeCustomers.toString(),
              'PELANGGAN TRANSAKSI',
              const Color(0xFFEEF2FF),
              const Color(0xFF0F62FE),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildClientStatCard(
              Icons.person_add,
              '+${summary.newCustomersThisMonth}',
              'BARU (BULAN INI)',
              const Color(0xFFECFDF5),
              const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientStatCard(
    IconData icon,
    String value,
    String label,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgColor == const Color(0xFFEEF2FF)
              ? const Color(0xFFC7D2FE)
              : const Color(0xFFA7F3D0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Donut Chart (Expense by Category)
  // -------------------------------------------------------------------------
  Widget _buildDonutChartSection(ReportSummary summary) {
    const categoryColors = [
      Color(0xFF0F62FE),
      Color(0xFFFDA4AF),
      Color(0xFFFCD34D),
      Color(0xFF34D399),
      Color(0xFFA78BFA),
      Color(0xFFFB923C),
    ];

    final entries = summary.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<double>(0, (s, e) => s + e.value);

    final sections = entries.asMap().entries.map((entry) {
      final colorIndex = entry.key % categoryColors.length;
      return PieChartSectionData(
        color: categoryColors[colorIndex],
        value: entry.value.value,
        title: '',
        radius: 8,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pengeluaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 35,
                          sections: sections.isNotEmpty
                              ? sections
                              : [
                                  PieChartSectionData(
                                    color: const Color(0xFFE2E8F0),
                                    value: 1,
                                    title: '',
                                    radius: 8,
                                  ),
                                ],
                        ),
                      ),
                      const Text(
                        'Ops',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: entries.asMap().entries.map((entry) {
                      final colorIndex = entry.key % categoryColors.length;
                      final pct = total > 0
                          ? (entry.value.value / total * 100).toStringAsFixed(0)
                          : '0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildDonutLegendItem(
                          categoryColors[colorIndex],
                          entry.value.key,
                          '$pct%',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendItem(Color color, String label, String percent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        Text(
          percent,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
