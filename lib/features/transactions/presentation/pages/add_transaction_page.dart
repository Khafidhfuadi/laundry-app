import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../domain/entities/transaction_entity.dart';
import '../controllers/transaction_controller.dart';
import '../../../customers/presentation/controllers/customer_controller.dart';
import '../../../services/presentation/controllers/service_controller.dart';
import '../../../outlet/presentation/controllers/outlet_controller.dart';
import '../../../outlet/presentation/controllers/active_outlet_controller.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;

  // Tipe Layanan
  String _serviceType = 'Reguler';

  // Data item yang akan dipesan
  final List<TransactionItemEntity> _items = [];
  
  // Tagihan
  String _paymentStatus = 'UNPAID';
  final _paidAmountController = TextEditingController(text: '0');
  
  // Catatan
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(outletControllerProvider.notifier).loadOutlets();
    ref.read(customerControllerProvider.notifier).loadCustomers();
    ref.read(serviceControllerProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  DateTime get _estimatedCompletionDate {
    if (_serviceType == 'Express') {
      return DateTime.now().add(const Duration(hours: 6));
    } else if (_serviceType == 'Same Day') {
      return DateTime.now().add(const Duration(hours: 24));
    } else {
      return DateTime.now().add(const Duration(days: 2));
    }
  }

  void _showAddServiceModal() {
    final serviceState = ref.read(serviceControllerProvider);
    if (!serviceState.hasValue) return;

    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Layanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: serviceState.value!.length,
                  itemBuilder: (context, index) {
                    final service = serviceState.value![index];
                    return ListTile(
                      leading: const Icon(Icons.dry_cleaning, color: Color(0xFF0F62FE)),
                      title: Text(service.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${formatter.format(service.price)} / ${service.unitType}'),
                      trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF0F62FE)),
                      onTap: () {
                        setState(() {
                          _items.add(
                            TransactionItemEntity(
                              id: '', // Diabaikan saat insert
                              transactionId: '',
                              serviceId: service.id,
                              quantity: 1.0,
                              subtotal: service.price,
                              service: service,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateItemQuantity(int index, double delta) {
    setState(() {
      final currentQty = _items[index].quantity;
      final newQty = currentQty + delta;
      if (newQty > 0) {
        final servicePrice = _items[index].service?.price ?? 0;
        _items[index] = TransactionItemEntity(
          id: _items[index].id,
          transactionId: _items[index].transactionId,
          serviceId: _items[index].serviceId,
          quantity: newQty,
          subtotal: newQty * servicePrice,
          service: _items[index].service,
        );
      }
    });
  }

  void _submitEvent() async {
    final activeOutletState = ref.read(activeOutletProvider);
    final outletId = activeOutletState.value?.id;

    if (!_formKey.currentState!.validate() ||
        _items.isEmpty ||
        outletId == null ||
        _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pastikan pelanggan dan minimal 1 layanan dipilih.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String generatedCode =
        'LND-${DateFormat('yMdhms').format(DateTime.now())}-${Random().nextInt(999)}';
    final double paidAmount =
        double.tryParse(_paidAmountController.text) ?? 0.0;

    String actualPaymentStatus = _paymentStatus;
    if (paidAmount >= _totalPrice && _totalPrice > 0) {
      actualPaymentStatus = 'PAID';
    } else if (paidAmount > 0) {
      actualPaymentStatus = 'PARTIAL';
    } else {
      actualPaymentStatus = 'UNPAID';
    }

    final newTransaction = TransactionEntity(
      id: '',
      transactionCode: generatedCode,
      outletId: outletId,
      customerId: _selectedCustomerId!,
      totalPrice: _totalPrice,
      status: 'PROCESS',
      paymentStatus: actualPaymentStatus,
      paidAmount: paidAmount,
      notes: _notesController.text,
      estimatedCompletionDate: _estimatedCompletionDate,
      items: _items,
      createdAt: DateTime.now(),
    );

    final success = await ref
        .read(transactionControllerProvider.notifier)
        .createTransaction(newTransaction);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil membuat transaksi baru.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat transaksi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Transaksi Baru',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerSection(),
              _buildServiceTypeSection(),
              _buildServiceListSection(formatter),
              _buildSummarySection(formatter),
              _buildNotesSection(),
              const SizedBox(height: 100), // Spacing for bottom button
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: _isLoading ? null : _submitEvent,
          icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send),
          label: Text(
            _isLoading ? 'Menyimpan...' : 'Simpan & Kirim WhatsApp',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F62FE),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    final customerState = ref.watch(customerControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pelanggan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          customerState.when(
            data: (customers) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Row(
                    children: [
                      Icon(Icons.person_search_outlined, color: Color(0xFF94A3B8)),
                      SizedBox(width: 8),
                      Text('Cari/Pilih Pelanggan'),
                    ],
                  ),
                  value: _selectedCustomerId,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                  items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.phoneNumber}'))).toList(),
                  onChanged: (v) => setState(() => _selectedCustomerId = v),
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Gagal memuat pelanggan: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipe Layanan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildServiceTypeCard('Reguler', Icons.access_time)),
              const SizedBox(width: 12),
              Expanded(child: _buildServiceTypeCard('Express', Icons.bolt)),
              const SizedBox(width: 12),
              Expanded(child: _buildServiceTypeCard('Same Day', Icons.rocket_launch)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeCard(String title, IconData icon) {
    final isSelected = _serviceType == title;
    return GestureDetector(
      onTap: () => setState(() => _serviceType = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceListSection(NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daftar Layanan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          if (_items.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                final serviceName = item.service?.fullName ?? 'Layanan ID: ${item.serviceId}';
                final servicePrice = item.service?.price ?? 0;
                final unit = item.service?.unitType ?? 'Kg';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.dry_cleaning, color: Color(0xFF0F62FE)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  serviceName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _items.removeAt(index)),
                                  child: const Icon(Icons.delete_outline, color: Color(0xFF94A3B8), size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatter.format(servicePrice)} / $unit',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _updateItemQuantity(index, -1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(Icons.remove, size: 16, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.quantity.toInt().toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _updateItemQuantity(index, 1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(Icons.add, size: 16, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatter.format(item.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF0F62FE),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          if (_items.isNotEmpty) const SizedBox(height: 16),
          
          GestureDetector(
            onTap: _showAddServiceModal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  style: BorderStyle.solid, 
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Layanan',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimasi Selesai', style: TextStyle(color: Color(0xFF64748B))),
                Row(
                  children: [
                    Text(
                      DateFormat('EEEE, d MMM • HH:mm', 'id_ID').format(_estimatedCompletionDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F62FE),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 14, color: Color(0xFF0F62FE)),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFE2E8F0)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status Pembayaran', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                SizedBox(
                  width: 140,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _paymentStatus,
                      style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0F62FE)),
                      items: const [
                        DropdownMenuItem(value: 'UNPAID', child: Text('Belum Bayar')),
                        DropdownMenuItem(value: 'PARTIAL', child: Text('DP / Sebagian')),
                        DropdownMenuItem(value: 'PAID', child: Text('Lunas Langsung')),
                      ],
                      onChanged: (v) => setState(() => _paymentStatus = v!),
                    ),
                  ),
                ),
              ],
            ),
            if (_paymentStatus != 'UNPAID') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _paidAmountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Diterima (Rp)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                 style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFE2E8F0)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Tagihan', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                Text(
                  formatter.format(_totalPrice),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F62FE),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Khusus',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Misal: Jangan pakai pemutih, kemeja digantung...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
