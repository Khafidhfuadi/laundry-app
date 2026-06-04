import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide showDateRangePicker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../outlet/presentation/controllers/active_outlet_controller.dart';
import '../../domain/entities/report_detail.dart';
import '../controllers/report_detail_controller.dart';
import '../widgets/date_range_picker.dart';

class ReportDetailPage extends ConsumerStatefulWidget {
  final ReportDetailType type;

  const ReportDetailPage({super.key, required this.type});

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  ReportDetailRangePreset _selectedPreset = ReportDetailRangePreset.last7Days;
  DateRangeResult? _customRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  DateTime _asDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTimeRange _resolveRangeFromPreset(ReportDetailRangePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case ReportDetailRangePreset.today:
        return DateTimeRange(start: today, end: today);
      case ReportDetailRangePreset.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case ReportDetailRangePreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case ReportDetailRangePreset.custom:
        if (_customRange != null) {
          return DateTimeRange(
            start: _asDateOnly(_customRange!.start),
            end: _asDateOnly(_customRange!.end),
          );
        }
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
    }
  }

  Future<void> _loadDetail() async {
    final outletState = ref.read(activeOutletProvider);
    final outletId = outletState.value?.id ?? '';
    if (outletId.isEmpty) return;

    final range = _resolveRangeFromPreset(_selectedPreset);
    await ref
        .read(reportDetailControllerProvider.notifier)
        .loadDetail(
          outletId: outletId,
          type: widget.type,
          startDate: range.start,
          endDate: range.end,
        );
  }

  Future<void> _onSelectPreset(ReportDetailRangePreset preset) async {
    if (preset == ReportDetailRangePreset.custom) {
      await _openCustomDatePicker();
      return;
    }

    setState(() {
      _selectedPreset = preset;
      _customRange = null;
    });
    await _loadDetail();
  }

  Future<void> _openCustomDatePicker() async {
    final result = await showDateRangePicker(
      context,
      initialRange: _customRange,
    );
    if (result == null) return;

    setState(() {
      _selectedPreset = ReportDetailRangePreset.custom;
      _customRange = result;
    });
    await _loadDetail();
  }

  /// Menghitung DateTimeRange yang sedang aktif untuk display.
  DateTimeRange _currentDisplayRange() {
    return _resolveRangeFromPreset(_selectedPreset);
  }

  String _title() {
    switch (widget.type) {
      case ReportDetailType.turnover:
        return 'Laporan Omset';
      case ReportDetailType.income:
        return 'Laporan Pendapatan';
      case ReportDetailType.expense:
        return 'Laporan Pengeluaran';
      case ReportDetailType.netProfit:
        return 'Laporan Laba / Rugi';
    }
  }

  Color _primaryColor() {
    switch (widget.type) {
      case ReportDetailType.turnover:
        return const Color(0xFF1D4ED8);
      case ReportDetailType.income:
        return const Color(0xFF0F62FE);
      case ReportDetailType.expense:
        return const Color(0xFFEF4444);
      case ReportDetailType.netProfit:
        return const Color(0xFF10B981);
    }
  }

  final _presetLabels = {
    ReportDetailRangePreset.today: 'Hari Ini',
    ReportDetailRangePreset.yesterday: 'Kemarin',
    ReportDetailRangePreset.last7Days: '7 Hari',
  };

  double _pointValue(ReportSeriesPoint p) {
    switch (widget.type) {
      case ReportDetailType.turnover:
        return p.turnover;
      case ReportDetailType.income:
        return p.income;
      case ReportDetailType.expense:
        return p.expense;
      case ReportDetailType.netProfit:
        return p.netProfit;
    }
  }

  String _labelForDate(DateTime date) {
    if (_selectedPreset == ReportDetailRangePreset.today ||
        _selectedPreset == ReportDetailRangePreset.yesterday ||
        _selectedPreset == ReportDetailRangePreset.last7Days) {
      return DateFormat('EEE', 'id_ID').format(date);
    }
    // Custom range
    final range = _currentDisplayRange();
    final totalDays = range.end.difference(range.start).inDays + 1;
    if (totalDays <= 14) {
      return DateFormat('d MMM', 'id_ID').format(date);
    }
    return DateFormat('d/M', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(reportDetailControllerProvider);
    final activeOutlet = ref.watch(activeOutletProvider);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: Text(
          _title(),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterRow(),
            _buildDateRangeLabel(),
            Expanded(
              child: activeOutlet.value == null
                  ? const Center(
                      child: Text(
                        'Pilih cabang terlebih dahulu.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : detailState.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFEF4444),
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Gagal memuat laporan:\n$error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadDetail,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (detail) => RefreshIndicator(
                        onRefresh: _loadDetail,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatter.format(detail.totalAmount),
                                    style: TextStyle(
                                      color: _primaryColor(),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLineChart(detail),
                            const SizedBox(height: 20),
                            const Text(
                              'Log Transaksi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (detail.logItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'Belum ada data pada rentang ini.',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              )
                            else
                              ...detail.logItems.map(
                                (item) => _buildLogItem(item, formatter),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final isCustomSelected = _selectedPreset == ReportDetailRangePreset.custom;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ..._presetLabels.entries.map((entry) {
            final isSelected = _selectedPreset == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => _onSelectPreset(entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryColor()
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF475569),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Kustom chip with dropdown icon
          GestureDetector(
            onTap: _openCustomDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCustomSelected
                    ? _primaryColor()
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: isCustomSelected
                    ? null
                    : Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kustom',
                    style: TextStyle(
                      color: isCustomSelected
                          ? Colors.white
                          : const Color(0xFF475569),
                      fontWeight: isCustomSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isCustomSelected
                        ? Colors.white
                        : const Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeLabel() {
    final range = _currentDisplayRange();
    final dateFormat = DateFormat('MMM d, yyyy');
    final startLabel = dateFormat.format(range.start);
    final endLabel = dateFormat.format(range.end);
    final isSingleDay =
        range.start.year == range.end.year &&
        range.start.month == range.end.month &&
        range.start.day == range.end.day;
    final rangeText = isSingleDay ? startLabel : '$startLabel - $endLabel';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          rangeText,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(ReportDetailState detail) {
    final values = detail.seriesPoints.map(_pointValue).toList();
    final maxValue = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final minValue = values.isNotEmpty
        ? values.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final padding = ((maxValue - minValue).abs() * 0.2).clamp(1000.0, 50000.0);
    final maxY = maxValue + padding;
    final minY = minValue < 0 ? minValue - padding : 0.0;
    final interval = values.length <= 8 ? 1 : (values.length / 6).ceil();
    final yInterval = ((maxY - minY) / 4).clamp(1.0, double.infinity);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: minY.toDouble(),
            maxY: maxY.toDouble(),
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    if (index < 0 || index >= detail.seriesPoints.length) {
                      return null;
                    }
                    final point = detail.seriesPoints[index];
                    final dateLabel = DateFormat(
                      'dd MMM yyyy',
                      'id_ID',
                    ).format(point.date);
                    return LineTooltipItem(
                      '$dateLabel\n${formatter.format(spot.y)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: ((maxY - minY) / 4).clamp(
                1.0,
                double.infinity,
              ),
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  interval: yInterval.toDouble(),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _formatYAxis(value),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= detail.seriesPoints.length) {
                      return const SizedBox.shrink();
                    }
                    if (i % interval != 0 &&
                        i != detail.seriesPoints.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _labelForDate(detail.seriesPoints[i].date),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  detail.seriesPoints.length,
                  (i) =>
                      FlSpot(i.toDouble(), _pointValue(detail.seriesPoints[i])),
                ),
                isCurved: true,
                color: _primaryColor(),
                barWidth: 2.5,
                dotData: FlDotData(show: detail.seriesPoints.length <= 10),
                belowBarData: BarAreaData(
                  show: true,
                  color: _primaryColor().withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(ReportLogItem item, NumberFormat formatter) {
    final isIncome = item.kind == ReportLogKind.income;
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final sign = isIncome ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.subtitle} • ${DateFormat('dd MMM yyyy', 'id_ID').format(item.date)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${formatter.format(item.amount)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatYAxis(double value) {
    final abs = value.abs();
    if (abs >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }
}
