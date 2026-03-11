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
import '../../../perfumes/presentation/controllers/perfume_controller.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  String? _selectedPerfumeId;
  DateTime? _customCompletionDate;

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
    ref.read(perfumeControllerProvider.notifier).refresh();
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
    if (_customCompletionDate != null) return _customCompletionDate!;
    if (_items.isEmpty) {
      return DateTime.now().add(const Duration(days: 2));
    }
    int maxHours = 0;
    for (var item in _items) {
      final hours = item.serviceVariant?.estimatedHours ?? 0;
      if (hours > maxHours) {
        maxHours = hours;
      }
    }
    if (maxHours == 0) maxHours = 48; // default 2 days
    return DateTime.now().add(Duration(hours: maxHours));
  }

  Future<void> _pickEstimatedDate() async {
    final initialDate = _estimatedCompletionDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        setState(() {
          _customCompletionDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showCustomerModal() {
    final customerState = ref.read(customerControllerProvider);
    if (!customerState.hasValue) return;

    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final filtered = customerState.value!.where((c) {
              if (searchQuery.isEmpty) return true;
              return c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  c.phoneNumber.contains(searchQuery);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pilih Pelanggan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/customers/add');
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Color(0xFF0F62FE),
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Pelanggan Baru',
                                  style: TextStyle(
                                    color: Color(0xFF0F62FE),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau nomor...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setStateModal(() => searchQuery = v),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('Pelanggan tidak ditemukan'),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final c = filtered[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFEEF2FF),
                                      child: Text(
                                        c.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF0F62FE),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(c.phoneNumber),
                                    onTap: () {
                                      setState(() {
                                        _selectedCustomerId = c.id;
                                      });
                                      Navigator.pop(ctx);
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
          },
        );
      },
    );
  }

  void _showAddServiceModal() {
    final serviceState = ref.read(serviceControllerProvider);
    if (!serviceState.hasValue) return;

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final filteredServices = serviceState.value!.where((s) {
              if (searchQuery.isEmpty) return true;
              return s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  s.variants.any(
                    (v) => v.variantName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
                  );
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pilih Layanan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/services');
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  color: Color(0xFF0F62FE),
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Kelola Layanan',
                                  style: TextStyle(
                                    color: Color(0xFF0F62FE),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari layanan atau varian...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setStateModal(() => searchQuery = v),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredServices.isEmpty
                            ? const Center(
                                child: Text('Layanan tidak ditemukan'),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredServices.length,
                                itemBuilder: (context, index) {
                                  final service = filteredServices[index];
                                  return ExpansionTile(
                                    leading: const Icon(
                                      Icons.dry_cleaning,
                                      color: Color(0xFF0F62FE),
                                    ),
                                    title: Text(
                                      service.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    children: service.variants
                                        .where(
                                          (v) =>
                                              searchQuery.isEmpty ||
                                              v.variantName
                                                  .toLowerCase()
                                                  .contains(
                                                    searchQuery.toLowerCase(),
                                                  ) ||
                                              service.name
                                                  .toLowerCase()
                                                  .contains(
                                                    searchQuery.toLowerCase(),
                                                  ),
                                        )
                                        .map((variant) {
                                          return ListTile(
                                            contentPadding:
                                                const EdgeInsets.only(
                                                  left: 72,
                                                  right: 16,
                                                ),
                                            title: Text(variant.variantName),
                                            subtitle: Text(
                                              '${formatter.format(variant.price)} / ${variant.unitType}',
                                            ),
                                            trailing: const Icon(
                                              Icons.add_circle_outline,
                                              color: Color(0xFF0F62FE),
                                            ),
                                            onTap: () {
                                              setState(() {
                                                _items.add(
                                                  TransactionItemEntity(
                                                    id: '', // Diabaikan saat insert
                                                    transactionId: '',
                                                    serviceVariantId:
                                                        variant.id,
                                                    quantity: 1.0,
                                                    subtotal: variant.price,
                                                    serviceVariant: variant
                                                        .copyWith(
                                                          service: service,
                                                        ),
                                                  ),
                                                );
                                              });
                                              Navigator.pop(ctx);
                                            },
                                          );
                                        })
                                        .toList(),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _editItemQuantity(int index) {
    final currentQty = _items[index].quantity;
    final controller = TextEditingController(
      text: currentQty.toString().replaceAll(RegExp(r'([.]*0)(?!.*\d)'), ''),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Kuantitas'),
        content: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Misal: 1.5',
            suffixText: 'Kg/Pcs',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (newQty != null && newQty > 0) {
                setState(() {
                  final servicePrice = _items[index].serviceVariant?.price ?? 0;
                  _items[index] = TransactionItemEntity(
                    id: _items[index].id,
                    transactionId: _items[index].transactionId,
                    serviceVariantId: _items[index].serviceVariantId,
                    quantity: newQty,
                    subtotal: newQty * servicePrice,
                    serviceVariant: _items[index].serviceVariant,
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _updateItemQuantity(int index, double delta) {
    setState(() {
      final currentQty = _items[index].quantity;
      final newQty = currentQty + delta;
      if (newQty > 0) {
        final servicePrice = _items[index].serviceVariant?.price ?? 0;
        _items[index] = TransactionItemEntity(
          id: _items[index].id,
          transactionId: _items[index].transactionId,
          serviceVariantId: _items[index].serviceVariantId,
          quantity: newQty,
          subtotal: newQty * servicePrice,
          serviceVariant: _items[index].serviceVariant,
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
          content: Text('Pastikan pelanggan dan minimal 1 layanan dipilih'),
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
      perfumeId: _selectedPerfumeId,
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
        print('Gagal membuat transaksi ${newTransaction.toJson()}');
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
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

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
              _buildServiceListSection(formatter),
              _buildPerfumeSection(),
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
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
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
    final String customerName = _selectedCustomerId == null
        ? 'Pilih Pelanggan'
        : customerState.maybeWhen(
            data: (list) {
              final c = list.firstWhere(
                (e) => e.id == _selectedCustomerId,
                orElse: () => list.first,
              );
              return '${c.name} - ${c.phoneNumber}';
            },
            orElse: () => 'Memuat...',
          );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pelanggan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showCustomerModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_search_outlined,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customerName,
                      style: TextStyle(
                        color: _selectedCustomerId == null
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF1E293B),
                        fontWeight: _selectedCustomerId == null
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_right,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfumeSection() {
    final perfumeState = ref.watch(perfumeControllerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilihan Parfum (Opsional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          perfumeState.when(
            data: (perfumes) => Container(
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
                      Icon(Icons.water_drop_outlined, color: Color(0xFF94A3B8)),
                      SizedBox(width: 8),
                      Text('Tidak Pakai Parfum / Default'),
                    ],
                  ),
                  value: _selectedPerfumeId,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF94A3B8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tidak Pakai Parfum / Default'),
                    ),
                    ...perfumes.map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedPerfumeId = v),
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Gagal memuat parfum: $e'),
          ),
        ],
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
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
                final serviceName = item.serviceVariant?.service?.name != null
                    ? '${item.serviceVariant!.service!.name} - ${item.serviceVariant!.variantName}'
                    : 'Layanan ID: ${item.serviceVariantId}';
                final servicePrice = item.serviceVariant?.price ?? 0;
                final unit = item.serviceVariant?.unitType ?? 'Kg';

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
                        child: const Icon(
                          Icons.dry_cleaning,
                          color: Color(0xFF0F62FE),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    serviceName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _items.removeAt(index)),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatter.format(servicePrice)} / $unit',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () =>
                                            _updateItemQuantity(index, -1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.remove,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _editItemQuantity(index),
                                        child: Text(
                                          item.quantity.toString().replaceAll(
                                            RegExp(r'([.]*0)(?!.*\d)'),
                                            '',
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () =>
                                            _updateItemQuantity(index, 1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.add,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
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
                const Text(
                  'Estimasi Selesai',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                Row(
                  children: [
                    Text(
                      DateFormat(
                        'EEEE, d MMM • HH:mm',
                        'id_ID',
                      ).format(_estimatedCompletionDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F62FE),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _pickEstimatedDate,
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: Color(0xFF0F62FE),
                        ),
                      ),
                    ),
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
                const Text(
                  'Status Pembayaran',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _paymentStatus,
                      style: const TextStyle(
                        color: Color(0xFF0F62FE),
                        fontWeight: FontWeight.bold,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF0F62FE),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'UNPAID',
                          child: Text('Belum Bayar'),
                        ),
                        DropdownMenuItem(
                          value: 'PARTIAL',
                          child: Text('DP / Sebagian'),
                        ),
                        DropdownMenuItem(
                          value: 'PAID',
                          child: Text('Lunas Langsung'),
                        ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                const Text(
                  'Total Tagihan',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Misal: Jangan pakai pemutih, kemeja digantung...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
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
