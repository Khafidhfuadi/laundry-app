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

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedOutletId;
  String? _selectedCustomerId;

  // Data item yang akan dipesan
  final List<TransactionItemEntity> _items = [];
  String? _selectedServiceId;
  final _qtyController = TextEditingController(text: '1');

  String _paymentStatus = 'UNPAID';
  final _paidAmountController = TextEditingController(text: '0');
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
    _qtyController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void _addItem() {
    if (_selectedServiceId == null) return;
    final qty = double.tryParse(_qtyController.text) ?? 1.0;

    // Cari data servis untuk mengambil harga
    final servicesState = ref.read(serviceControllerProvider);
    if (!servicesState.hasValue) return;

    final selectedService = servicesState.value!.firstWhere(
      (s) => s.id == _selectedServiceId,
    );
    final subtotal = qty * selectedService.price;

    setState(() {
      _items.add(
        TransactionItemEntity(
          id: '', // Diabaikan saat insert
          transactionId: '',
          serviceId: selectedService.id,
          quantity: qty,
          subtotal: subtotal,
          service: selectedService,
        ),
      );
      _selectedServiceId = null;
      _qtyController.text = '1';
    });
  }

  void _submitEvent() async {
    if (!_formKey.currentState!.validate() ||
        _items.isEmpty ||
        _selectedOutletId == null ||
        _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pastikan semua form dan item cucian telah diisi.'),
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

    // Perbaikan status payment auto deteksi lunas jika paid >= total
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
      outletId: _selectedOutletId!,
      customerId: _selectedCustomerId!,
      totalPrice: _totalPrice,
      status: 'PROCESS',
      paymentStatus: actualPaymentStatus,
      paidAmount: paidAmount,
      notes: '',
      estimatedCompletionDate: DateTime.now().add(
        const Duration(days: 2),
      ), // Default estimasi 2 hari
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
    final outletState = ref.watch(outletControllerProvider);
    final customerState = ref.watch(customerControllerProvider);
    final serviceState = ref.watch(serviceControllerProvider);

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Transaksi Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: CABANG & PELANGGAN ---
              const Text(
                'Data Dasar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              // Outlet Dropdown
              outletState.when(
                data: (outlets) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Cabang / Outlet',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedOutletId,
                  items: outlets
                      .map(
                        (o) =>
                            DropdownMenuItem(value: o.id, child: Text(o.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedOutletId = v),
                  validator: (v) => v == null ? 'Wajib dipilih' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Gagal memuat cabang: $e'),
              ),
              const SizedBox(height: 12),

              // Customer Dropdown
              customerState.when(
                data: (customers) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Pilih Pelanggan',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCustomerId,
                  items: customers
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} - ${c.phoneNumber}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCustomerId = v),
                  validator: (v) => v == null ? 'Wajib dipilih' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Gagal memuat pelanggan: $e'),
              ),
              const SizedBox(height: 24),

              // --- SECTION 2: ITEM LAYANAN ---
              const Text(
                'Item Cucian',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: serviceState.when(
                      data: (services) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Layanan',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        value: _selectedServiceId,
                        items: services
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  '${s.fullName} (${formatter.format(s.price)})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedServiceId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text('Error load layanan'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Jml/Kg',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Item'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Keranjang Item
              if (_items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada item ditambahkan.'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 1,
                      child: ListTile(
                        dense: true,
                        title: Text(
                          item.service?.fullName ??
                              'Layanan ID: ${item.serviceId}',
                        ),
                        subtitle: Text(
                          '${item.quantity} x ${formatter.format(item.service?.price ?? 0)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatter.format(item.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _items.removeAt(index)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const Divider(height: 32),

              // --- SECTION 3: PEMBAYARAN ---
              const Text(
                'Tagihan & Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Biaya:', style: TextStyle(fontSize: 16)),
                  Text(
                    formatter.format(_totalPrice),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Status Pembayaran',
                  border: OutlineInputBorder(),
                ),
                value: _paymentStatus,
                items: const [
                  DropdownMenuItem(
                    value: 'UNPAID',
                    child: Text('Belum Bayar (Nanti)'),
                  ),
                  DropdownMenuItem(
                    value: 'PARTIAL',
                    child: Text('Bayar Sebagian (DP)'),
                  ),
                  DropdownMenuItem(
                    value: 'PAID',
                    child: Text('Lunas Langsung'),
                  ),
                ],
                onChanged: (v) => setState(() => _paymentStatus = v!),
              ),
              if (_paymentStatus != 'UNPAID') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paidAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Uang Diterima (Rp)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(
            onPressed: _isLoading ? null : _submitEvent,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Simpan Transaksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
