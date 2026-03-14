import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../outlet/presentation/controllers/active_outlet_controller.dart';
import '../controllers/report_customer_insight_controller.dart';

enum CustomerInsightRangePreset {
  today,
  last7Days,
  last30Days,
  thisMonth,
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
  DateTimeRange? _customRange;

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
      case CustomerInsightRangePreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case CustomerInsightRangePreset.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case CustomerInsightRangePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final defaultRange =
          _customRange ??
          DateTimeRange(
            start: today.subtract(const Duration(days: 6)),
            end: today,
          );

      final picked = await showDateRangePicker(
        context: context,
        firstDate: today.subtract(const Duration(days: 365)),
        lastDate: today,
        initialDateRange: defaultRange,
        helpText: 'Pilih Rentang Tanggal',
      );
      if (picked == null) return;

      setState(() {
        _selectedPreset = CustomerInsightRangePreset.custom;
        _customRange = DateTimeRange(
          start: _asDateOnly(picked.start),
          end: _asDateOnly(picked.end),
        );
      });
      await _loadInsight();
      return;
    }

    setState(() => _selectedPreset = preset);
    await _loadInsight();
  }

  String _presetLabel(CustomerInsightRangePreset preset) {
    switch (preset) {
      case CustomerInsightRangePreset.today:
        return 'Hari Ini';
      case CustomerInsightRangePreset.last7Days:
        return '7 Hari Terakhir';
      case CustomerInsightRangePreset.last30Days:
        return '30 Hari Terakhir';
      case CustomerInsightRangePreset.thisMonth:
        return 'Bulan Ini';
      case CustomerInsightRangePreset.custom:
        return 'Kustom';
    }
  }

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
    const presets = [
      CustomerInsightRangePreset.today,
      CustomerInsightRangePreset.last7Days,
      CustomerInsightRangePreset.last30Days,
      CustomerInsightRangePreset.thisMonth,
      CustomerInsightRangePreset.custom,
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isSelected = _selectedPreset == preset;
          return GestureDetector(
            onTap: () => _onSelectPreset(preset),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Text(
                _presetLabel(preset),
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: presets.length,
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
