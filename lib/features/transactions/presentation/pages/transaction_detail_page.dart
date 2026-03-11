import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction_entity.dart';
import '../controllers/transaction_controller.dart';

class TransactionDetailPage extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  ConsumerState<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState
    extends ConsumerState<TransactionDetailPage> {
  bool _isUpdatingStatus = false;

  final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  // Status workflow order
  static const List<Map<String, String>> _workflowSteps = [
    {'key': 'RECEIVED', 'label': 'DITERIMA'},
    {'key': 'PROCESS', 'label': 'PROSES'},
    {'key': 'READY', 'label': 'SELESAI'},
    {'key': 'PICKED_UP', 'label': 'DIAMBIL'},
  ];

  int _getWorkflowIndex(String status) {
    switch (status) {
      case 'PROCESS':
        return 1;
      case 'READY':
        return 2;
      case 'COMPLETED':
      case 'PICKED_UP':
        return 3;
      default:
        return 0;
    }
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'PROCESS':
        return 'READY';
      case 'READY':
        return 'COMPLETED';
      case 'COMPLETED':
        return 'PICKED_UP';
      default:
        return 'PROCESS';
    }
  }

  String _getNextStatusLabel(String currentStatus) {
    switch (currentStatus) {
      case 'PROCESS':
        return 'Tandai Selesai';
      case 'READY':
        return 'Tandai Diambil';
      case 'COMPLETED':
        return 'Tandai Sudah Diambil';
      default:
        return 'Update Status';
    }
  }

  Future<void> _updateStatus(TransactionEntity trx) async {
    if (_isUpdatingStatus) return;

    final nextStatus = _getNextStatus(trx.status);

    setState(() => _isUpdatingStatus = true);

    final success = await ref
        .read(transactionControllerProvider.notifier)
        .updateStatus(trx.id, nextStatus);

    if (mounted) {
      setState(() => _isUpdatingStatus = false);
      if (success) {
        // Refresh detail
        ref.invalidate(transactionDetailProvider(widget.transactionId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diperbarui')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsPaid(TransactionEntity trx) async {
    final remainingAmount = trx.totalPrice - trx.paidAmount;
    final success = await ref
        .read(transactionControllerProvider.notifier)
        .addPayment(trx.id, remainingAmount);

    if (mounted) {
      if (success) {
        ref.invalidate(transactionDetailProvider(widget.transactionId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran berhasil ditandai lunas')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui status pembayaran'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(transactionDetailProvider(widget.transactionId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: detailAsync.when(
        data: (trx) => _buildContent(trx),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F62FE)),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat detail transaksi',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(
                  transactionDetailProvider(widget.transactionId),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TransactionEntity trx) {
    final bool isFinished =
        trx.status == 'COMPLETED' || trx.status == 'PICKED_UP';

    return Column(
      children: [
        // AppBar
        _buildAppBar(trx),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(trx),
                _buildWorkflowProgress(trx),
                _buildDivider(),
                _buildCustomerSection(trx),
                _buildDivider(),
                _buildItemizedBill(trx),
                _buildDivider(),
                _buildDateSection(trx),
                _buildPaymentMethodSection(),
                if (trx.notes.isNotEmpty) ...[
                  _buildDivider(),
                  _buildNotesSection(trx),
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),

        // Bottom action buttons
        if (!isFinished) _buildBottomActions(trx),
      ],
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────

  Widget _buildAppBar(TransactionEntity trx) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRANSACTION ID',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${trx.transactionCode}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.print_outlined,
                      color: Color(0xFF64748B), size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur cetak segera hadir')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Color(0xFF64748B), size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── STATUS BANNER ────────────────────────────────────────────────────

  Widget _buildStatusBanner(TransactionEntity trx) {
    Color statusColor;
    Color statusBgColor;
    String statusText;
    final bool isPaid = trx.paymentStatus == 'PAID';

    switch (trx.paymentStatus) {
      case 'PAID':
        statusText = 'LUNAS';
        statusColor = const Color(0xFF059669);
        statusBgColor = const Color(0xFFD1FAE5);
        break;
      case 'PARTIAL':
        statusText = 'SEBAGIAN';
        statusColor = const Color(0xFFD97706);
        statusBgColor = const Color(0xFFFEF3C7);
        break;
      default:
        statusText = 'BELUM BAYAR';
        statusColor = const Color(0xFFDC2626);
        statusBgColor = const Color(0xFFFEE2E2);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS BAYAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL TAGIHAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatter.format(trx.totalPrice),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tombol Tandai Lunas
          if (!isPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _markAsPaid(trx),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text(
                  'TANDAI LUNAS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(color: Color(0xFF059669)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── WORKFLOW PROGRESS ────────────────────────────────────────────────

  Widget _buildWorkflowProgress(TransactionEntity trx) {
    final currentIndex = _getWorkflowIndex(trx.status);

    // Badge for workflow status
    String badgeText;
    Color badgeColor;
    Color badgeBgColor;

    if (trx.status == 'COMPLETED' || trx.status == 'PICKED_UP') {
      badgeText = 'COMPLETED';
      badgeColor = const Color(0xFF059669);
      badgeBgColor = const Color(0xFFD1FAE5);
    } else {
      badgeText = 'IN-PROGRESS';
      badgeColor = const Color(0xFF0F62FE);
      badgeBgColor = const Color(0xFFE8F0FE);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WORKFLOW PROGRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Timeline progress - flat approach: circles & lines in one Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _buildTimelineRow(currentIndex),
            ),
          ),
          const SizedBox(height: 10),
          // Labels row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              children: List.generate(_workflowSteps.length, (index) {
                final isActive = index <= currentIndex;
                final isCurrent = index == currentIndex;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        _workflowSteps[index]['label']!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF0F62FE)
                              : Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (index == 0)
                        Text(
                          DateFormat('dd MMM HH:mm').format(trx.createdAt.toLocal()),
                          style: TextStyle(
                            fontSize: 8,
                            color: isActive
                                ? const Color(0xFF0F62FE)
                                : Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineRow(int currentIndex) {
    final List<Widget> widgets = [];

    for (int i = 0; i < _workflowSteps.length; i++) {
      final isActive = i <= currentIndex;
      final isCurrent = i == currentIndex;

      // Add connecting line before circle (except for first)
      if (i > 0) {
        widgets.add(
          Expanded(
            child: Container(
              height: 3,
              color: isActive
                  ? const Color(0xFF0F62FE)
                  : const Color(0xFFE2E8F0),
            ),
          ),
        );
      }

      // Add circle
      widgets.add(
        Container(
          width: isCurrent ? 28 : 22,
          height: isCurrent ? 28 : 22,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F62FE) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? const Color(0xFF0F62FE)
                  : const Color(0xFFE2E8F0),
              width: 2.5,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F62FE).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: isActive
              ? Icon(
                  isCurrent ? Icons.radio_button_checked : Icons.check,
                  color: Colors.white,
                  size: isCurrent ? 16 : 12,
                )
              : null,
        ),
      );
    }

    return widgets;
  }

  // ─── CUSTOMER SECTION ─────────────────────────────────────────────────

  Widget _buildCustomerSection(TransactionEntity trx) {
    final customer = trx.customer;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PELANGGAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            customer?.name ?? 'Tanpa Nama',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          if (customer?.phoneNumber != null &&
              customer!.phoneNumber.isNotEmpty)
            Text(
              customer.phoneNumber,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F62FE),
                fontWeight: FontWeight.w500,
              ),
            ),
          if (customer?.address != null && customer!.address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customer.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── ITEMIZED BILL ────────────────────────────────────────────────────

  Widget _buildItemizedBill(TransactionEntity trx) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ITEMIZED BILL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Items
          ...trx.items.map((item) {
            final variant = item.serviceVariant;
            final serviceName = variant?.service?.name ?? 'Layanan';
            final variantName = variant?.variantName ?? '';
            final displayName = variantName.isNotEmpty
                ? '$serviceName + $variantName'
                : serviceName;
            final unitType = variant?.unitType ?? 'Pcs';
            final price = variant?.price ?? 0;
            final qtyStr = item.quantity == item.quantity.roundToDouble()
                ? item.quantity.toInt().toString()
                : item.quantity.toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$qtyStr $unitType @ ${_formatter.format(price)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatter.format(item.subtotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Subtotal
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SUBTOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _formatter.format(trx.totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── DATE SECTION ─────────────────────────────────────────────────────

  Widget _buildDateSection(TransactionEntity trx) {
    final bool isOverdue =
        trx.estimatedCompletionDate.isBefore(DateTime.now()) &&
            trx.status != 'COMPLETED' &&
            trx.status != 'PICKED_UP';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHECK-IN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateFormatter.format(trx.createdAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DUE DATE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateFormatter.format(trx.estimatedCompletionDate.toLocal()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOverdue
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PAYMENT METHOD ───────────────────────────────────────────────────

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'METODE BAYAR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'TUNAI (CASH)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ─── NOTES SECTION ────────────────────────────────────────────────────

  Widget _buildNotesSection(TransactionEntity trx) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFF57C00), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'KETERANGAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange[800],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"${trx.notes}"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM ACTIONS ───────────────────────────────────────────────────

  Widget _buildBottomActions(TransactionEntity trx) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Update status button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isUpdatingStatus ? null : () => _updateStatus(trx),
                icon: _isUpdatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _isUpdatingStatus
                      ? 'Memperbarui...'
                      : 'UPDATE STATUS TRANSAKSI',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F62FE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // WhatsApp button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur kirim WhatsApp segera hadir'),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text(
                  'KIRIM ULANG WHATSAPP',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: const Divider(color: Color(0xFFF1F5F9), thickness: 1),
    );
  }
}
