import 'package:flutter/material.dart' hide showDateRangePicker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../outlet/presentation/controllers/active_outlet_controller.dart';
import '../controllers/report_customer_insight_controller.dart';
import '../widgets/date_range_picker.dart';

enum CustomerInsightRangePreset {
  today,
  yesterday,
  last7Days,
  custom,
}

class ReportCustomerInsightPage extends ConsumerStatefulWidget {
  const ReportCustomerInsightPage({super.key});

  @override
  ConsumerState<ReportCustomerInsightPage> createState() =>
      _ReportCustomerInsightPageState();
}

class _ReportCustomerInsightPageState
    extends ConsumerState<ReportCustomerInsightPage> {
  CustomerInsightRangePreset _selectedPreset =
      CustomerInsightRangePreset.last7Days;
  DateRangeResult? _customRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInsight());
  }

  DateTime _asDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTimeRange _resolveRangeFromPreset(CustomerInsightRangePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case CustomerInsightRangePreset.today:
        return DateTimeRange(start: today, end: today);
      case CustomerInsightRangePreset.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case CustomerInsightRangePreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case CustomerInsightRangePreset.custom:
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

  Future<void> _loadInsight() async {
    final outletState = ref.read(activeOutletProvider);
    final outletId = outletState.value?.id ?? '';
    if (outletId.isEmpty) return;

    final range = _resolveRangeFromPreset(_selectedPreset);
    await ref
        .read(reportCustomerInsightControllerProvider.notifier)
        .loadInsight(
          outletId: outletId,
          startDate: range.start,
          endDate: range.end,
        );
  }

  Future<void> _onSelectPreset(CustomerInsightRangePreset preset) async {
    if (preset == CustomerInsightRangePreset.custom) {
      await _openCustomDatePicker();
      return;
    }

    setState(() {
      _selectedPreset = preset;
      _customRange = null;
    });
    await _loadInsight();
  }

  Future<void> _openCustomDatePicker() async {
    final result = await showDateRangePicker(
      context,
      initialRange: _customRange,
    );
    if (result == null) return;

    setState(() {
      _selectedPreset = CustomerInsightRangePreset.custom;
      _customRange = result;
    });
    await _loadInsight();
  }

  DateTimeRange _currentDisplayRange() {
    return _resolveRangeFromPreset(_selectedPreset);
  }

  final _presetLabels = {
    CustomerInsightRangePreset.today: 'Hari Ini',
    CustomerInsightRangePreset.yesterday: 'Kemarin',
    CustomerInsightRangePreset.last7Days: '7 Hari',
  };

  @override
  Widget build(BuildContext context) {
    final insightState = ref.watch(reportCustomerInsightControllerProvider);
    final activeOutlet = ref.watch(activeOutletProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: const Text(
          'Insight Customer',
          style: TextStyle(
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
                  : insightState.when(
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
                                'Gagal memuat insight customer:\n$error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadInsight,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (insight) => RefreshIndicator(
                        onRefresh: _loadInsight,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    title: 'Customer Aktif',
                                    value: insight.activeCustomers.toString(),
                                    color: const Color(0xFF1D4ED8),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildSummaryCard(
                                    title: 'Customer Baru',
                                    value: insight.newCustomers.toString(),
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildSummaryCard(
                                    title: 'Total Transaksi',
                                    value: insight.totalTransactions.toString(),
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Top Customer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (insight.customers.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'Belum ada transaksi customer pada rentang ini.',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              )
                            else
                              ...insight.customers.map(
                                (item) => _buildCustomerTile(
                                  item: item,
                                  currencyFormatter: currencyFormatter,
                                ),
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
    final isCustomSelected =
        _selectedPreset == CustomerInsightRangePreset.custom;

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
          GestureDetector(
            onTap: _openCustomDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCustomSelected
                    ? const Color(0xFF0F62FE)
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

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTile({
    required CustomerInsightItem item,
    required NumberFormat currencyFormatter,
  }) {
    final dateLabel = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(item.lastTransactionDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.customerName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                'Transaksi: ${item.transactionCount}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              Text(
                'Omset: ${currencyFormatter.format(item.totalOmset)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Pendapatan: ${currencyFormatter.format(item.totalPendapatan)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Transaksi terakhir: $dateLabel',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
