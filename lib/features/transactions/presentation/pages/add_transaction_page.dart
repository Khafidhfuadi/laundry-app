import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../domain/entities/transaction_entity.dart';
import '../../../customers/domain/entities/customer_entity.dart';
import '../controllers/transaction_controller.dart';
import '../../../customers/presentation/controllers/customer_controller.dart';
import '../../../customers/presentation/widgets/add_customer_bottom_sheet.dart';
import '../../../services/presentation/controllers/service_controller.dart';
import '../../../outlet/presentation/controllers/outlet_controller.dart';
import '../../../outlet/presentation/controllers/active_outlet_controller.dart';
import '../../../perfumes/presentation/controllers/perfume_controller.dart';
import '../../../../core/utils/whatsapp_helper.dart';

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

  String _formatQuantity(double quantity) {
    final isWhole = quantity == quantity.roundToDouble();
    if (isWhole) return quantity.toInt().toString();
    return quantity
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
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

  void _showEstimatedDateModal() {
    final now = DateTime.now();

    final presets = [
      _DatePreset(
        'Hari Ini',
        Icons.light_mode_rounded,
        now.add(const Duration(hours: 6)),
        const Color(0xFFF97316),
        const Color(0xFFFFF7ED),
      ),
      _DatePreset(
        'Besok',
        Icons.wb_sunny_rounded,
        now.add(const Duration(days: 1)),
        const Color(0xFF0F62FE),
        const Color(0xFFEEF2FF),
      ),
      _DatePreset(
        '2 Hari',
        Icons.calendar_today_rounded,
        now.add(const Duration(days: 2)),
        const Color(0xFF10B981),
        const Color(0xFFECFDF5),
      ),
      _DatePreset(
        '3 Hari',
        Icons.date_range_rounded,
        now.add(const Duration(days: 3)),
        const Color(0xFF8B5CF6),
        const Color(0xFFF5F3FF),
      ),
      _DatePreset(
        '1 Minggu',
        Icons.view_week_rounded,
        now.add(const Duration(days: 7)),
        const Color(0xFFEC4899),
        const Color(0xFFFDF2F8),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag indicator
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFF0F62FE),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimasi Selesai',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        DateFormat(
                          'EEEE, d MMM yyyy • HH:mm',
                          'id_ID',
                        ).format(_estimatedCompletionDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih cepat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Preset grid
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.0,
                children: presets.map((p) {
                  final isActive =
                      _customCompletionDate != null &&
                      _customCompletionDate!.day == p.date.day &&
                      _customCompletionDate!.month == p.date.month;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _customCompletionDate = p.date);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isActive ? p.color : p.bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? p.color : p.color.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            p.icon,
                            size: 16,
                            color: isActive ? Colors.white : p.color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : p.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              // Custom picker
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickCustomDateTime();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_calendar_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Pilih Tanggal & Waktu Manual',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCustomDateTime() async {
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

    final List<Color> avatarColors = [
      const Color(0xFF0F62FE),
      const Color(0xFF10B981),
      const Color(0xFFF97316),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final filtered = customerState.value!.where((c) {
              if (searchQuery.isEmpty) return true;
              return c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  c.phoneNumber.contains(searchQuery);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag indicator
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pilih Pelanggan',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${customerState.value!.length} pelanggan terdaftar',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                showAddCustomerBottomSheet(context).then((_) {
                                  ref
                                      .read(customerControllerProvider.notifier)
                                      .loadCustomers();
                                });
                              },
                              icon: const Icon(
                                Icons.person_add_rounded,
                                size: 16,
                              ),
                              label: const Text('Baru'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0F62FE),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            autofocus: false,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Cari nama atau nomor HP...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (v) =>
                                setStateModal(() => searchQuery = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      // Customer list
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.person_search_rounded,
                                        size: 40,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Pelanggan tidak ditemukan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  24,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final c = filtered[index];
                                  final isSelected =
                                      _selectedCustomerId == c.id;
                                  final initials = c.name.isNotEmpty
                                      ? c.name
                                            .trim()
                                            .split(' ')
                                            .take(2)
                                            .map((w) => w[0].toUpperCase())
                                            .join()
                                      : '?';
                                  final color =
                                      avatarColors[c.name.hashCode.abs() %
                                          avatarColors.length];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () {
                                          setState(
                                            () => _selectedCustomerId = c.id,
                                          );
                                          Navigator.pop(ctx);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFFEEF2FF)
                                                : const Color(0xFFFAFBFF),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF0F62FE)
                                                  : const Color(0xFFE8EEFF),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(
                                                    0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    initials,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      c.name,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? const Color(
                                                                0xFF0F62FE,
                                                              )
                                                            : const Color(
                                                                0xFF1E293B,
                                                              ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.phone_outlined,
                                                          size: 12,
                                                          color: Color(
                                                            0xFF94A3B8,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          c.phoneNumber,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: Color(
                                                                  0xFF64748B,
                                                                ),
                                                              ),
                                                        ),
                                                        if (c.totalTransactions >
                                                            0) ...[
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFE0E7FF,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              '${c.totalTransactions}x',
                                                              style: const TextStyle(
                                                                fontSize: 10,
                                                                color: Color(
                                                                  0xFF3730A3,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFF0F62FE,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
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
    final Set<String> expandedServiceIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

            if (searchQuery.isNotEmpty) {
              for (final s in filteredServices) {
                expandedServiceIds.add(s.id);
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag indicator
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pilih Layanan',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${filteredServices.fold(0, (s, sv) => s + sv.variants.length)} varian tersedia',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.push('/services');
                              },
                              icon: const Icon(Icons.tune_rounded, size: 16),
                              label: const Text('Kelola Layanan'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0F62FE),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Cari layanan atau varian...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (v) =>
                                setStateModal(() => searchQuery = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      // Service list
                      Expanded(
                        child: filteredServices.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.search_off_rounded,
                                        size: 40,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Layanan tidak ditemukan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  24,
                                ),
                                itemCount: filteredServices.length,
                                itemBuilder: (context, index) {
                                  final service = filteredServices[index];
                                  final isExpanded =
                                      expandedServiceIds.contains(service.id) ||
                                      searchQuery.isNotEmpty;
                                  final filteredVariants = service.variants
                                      .where(
                                        (v) =>
                                            searchQuery.isEmpty ||
                                            v.variantName
                                                .toLowerCase()
                                                .contains(
                                                  searchQuery.toLowerCase(),
                                                ) ||
                                            service.name.toLowerCase().contains(
                                              searchQuery.toLowerCase(),
                                            ),
                                      )
                                      .toList();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAFBFF),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFE8EEFF),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // Service header (tap to expand)
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () => setStateModal(() {
                                                if (expandedServiceIds.contains(
                                                  service.id,
                                                )) {
                                                  expandedServiceIds.remove(
                                                    service.id,
                                                  );
                                                } else {
                                                  expandedServiceIds.add(
                                                    service.id,
                                                  );
                                                }
                                              }),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFEEF2FF,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .dry_cleaning_rounded,
                                                        color: Color(
                                                          0xFF0F62FE,
                                                        ),
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            service.name,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                    0xFF1E293B,
                                                                  ),
                                                                ),
                                                          ),
                                                          Text(
                                                            '${filteredVariants.length} varian',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                    0xFF94A3B8,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    AnimatedRotation(
                                                      turns: isExpanded
                                                          ? 0.5
                                                          : 0,
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .keyboard_arrow_down_rounded,
                                                        color: Color(
                                                          0xFF94A3B8,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Variants
                                          if (isExpanded) ...[
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFFE8EEFF),
                                            ),
                                            ...filteredVariants.map((variant) {
                                              final alreadyAdded = _items
                                                  .where(
                                                    (item) =>
                                                        item.serviceVariantId ==
                                                        variant.id,
                                                  )
                                                  .length;

                                              return Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _items.add(
                                                        TransactionItemEntity(
                                                          id: '',
                                                          transactionId: '',
                                                          serviceVariantId:
                                                              variant.id,
                                                          quantity: 1.0,
                                                          subtotal:
                                                              variant.price,
                                                          serviceVariant:
                                                              variant.copyWith(
                                                                service:
                                                                    service,
                                                              ),
                                                        ),
                                                      );
                                                    });
                                                    setStateModal(() {});
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                variant
                                                                    .variantName,
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                    0xFF1E293B,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    '${formatter.format(variant.price)} / ${variant.unitType}',
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Color(
                                                                        0xFF64748B,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  if (variant
                                                                          .estimatedHours >
                                                                      0) ...[
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(
                                                                          0xFFF0FDF4,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              4,
                                                                            ),
                                                                      ),
                                                                      child: Text(
                                                                        variant.estimatedHours >=
                                                                                24
                                                                            ? '~${variant.estimatedHours ~/ 24}h'
                                                                            : '~${variant.estimatedHours}j',
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              10,
                                                                          color: Color(
                                                                            0xFF16A34A,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (alreadyAdded >
                                                            0) ...[
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFDCFCE7,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              '×$alreadyAdded',
                                                              style: const TextStyle(
                                                                color: Color(
                                                                  0xFF16A34A,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                        ],
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                7,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFF0F62FE,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  9,
                                                                ),
                                                          ),
                                                          child: const Icon(
                                                            Icons.add_rounded,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      // Done button
                      if (_items.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            MediaQuery.of(context).padding.bottom + 12,
                          ),
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.check_rounded),
                            label: Text('Selesai (${_items.length} layanan)'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F62FE),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
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
    final customerState = ref.read(customerControllerProvider);
    final customers = customerState.asData?.value ?? const <CustomerEntity>[];
    CustomerEntity? selectedCustomer;
    for (final customer in customers) {
      if (customer.id == _selectedCustomerId) {
        selectedCustomer = customer;
        break;
      }
    }

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
    // Tentukan paid amount dan payment status berdasarkan pilihan user
    double paidAmount;
    String actualPaymentStatus;

    if (_paymentStatus == 'PAID') {
      // Lunas Langsung: bayar penuh
      paidAmount = _totalPrice;
      actualPaymentStatus = 'PAID';
    } else if (_paymentStatus == 'PARTIAL') {
      // DP / Sebagian: ambil dari input
      paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
      if (paidAmount >= _totalPrice && _totalPrice > 0) {
        actualPaymentStatus = 'PAID';
      } else if (paidAmount > 0) {
        actualPaymentStatus = 'PARTIAL';
      } else {
        actualPaymentStatus = 'UNPAID';
      }
    } else {
      // Belum Bayar
      paidAmount = 0.0;
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
        bool waOpened = false;
        if (selectedCustomer != null &&
            selectedCustomer.phoneNumber.trim().isNotEmpty) {
          final formatter = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp',
            decimalDigits: 0,
          );
          final itemLines = _items.map((item) {
            final serviceName = item.serviceVariant?.service?.name ?? 'Layanan';
            final variantName = item.serviceVariant?.variantName ?? '';
            final unitType = item.serviceVariant?.unitType ?? 'Kg';
            final label = variantName.isEmpty
                ? serviceName
                : '$serviceName - $variantName';
            return '$label (${_formatQuantity(item.quantity)} $unitType) = ${formatter.format(item.subtotal)}';
          }).toList();

          waOpened = await WhatsAppHelper.sendTransactionSummary(
            phoneNumber: selectedCustomer.phoneNumber,
            customerName: selectedCustomer.name,
            transactionCode: generatedCode,
            transactionDate: newTransaction.createdAt,
            estimatedCompletionDate: newTransaction.estimatedCompletionDate,
            itemLines: itemLines,
            totalAmount: newTransaction.totalPrice,
            paidAmount: newTransaction.paidAmount,
            paymentStatus: newTransaction.paymentStatus,
            outletName: activeOutletState.value?.name ?? 'Laundry App',
            notes: newTransaction.notes,
          );
        }

        if (!mounted) return;
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              waOpened
                  ? 'Transaksi berhasil dibuat, WhatsApp pelanggan sudah dibuka.'
                  : 'Berhasil membuat transaksi baru.',
            ),
          ),
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
              : const Icon(Icons.save),
          label: Text(
            _isLoading ? 'Menyimpan...' : 'Simpan',
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

    final selectedCustomer = _selectedCustomerId == null
        ? null
        : customerState.maybeWhen(
            data: (list) {
              try {
                return list.firstWhere((e) => e.id == _selectedCustomerId);
              } catch (_) {
                return null;
              }
            },
            orElse: () => null,
          );

    final List<Color> avatarColors = [
      const Color(0xFF0F62FE),
      const Color(0xFF10B981),
      const Color(0xFFF97316),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedCustomer != null
                      ? const Color(0xFF0F62FE)
                      : const Color(0xFFE2E8F0),
                  width: selectedCustomer != null ? 1.5 : 1,
                ),
              ),
              child: selectedCustomer != null
                  ? Row(
                      children: [
                        Builder(
                          builder: (_) {
                            final initials = selectedCustomer.name.isNotEmpty
                                ? selectedCustomer.name
                                      .trim()
                                      .split(' ')
                                      .take(2)
                                      .map((w) => w[0].toUpperCase())
                                      .join()
                                : '?';
                            final color =
                                avatarColors[selectedCustomer.name.hashCode
                                        .abs() %
                                    avatarColors.length];
                            return Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCustomer.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F62FE),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedCustomer.phoneNumber,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCustomerId = null),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_search_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Pilih Pelanggan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_right_rounded,
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

  void _showPerfumeModal(List<dynamic> perfumes) {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final filtered = perfumes.where((p) {
              if (searchQuery.isEmpty) return true;
              return p.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag indicator
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF4FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.water_drop_rounded,
                                color: Color(0xFF9333EA),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih Parfum',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  '${perfumes.length} parfum tersedia',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Cari parfum...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (v) =>
                                setStateModal(() => searchQuery = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      // List
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            // "No perfume" option
                            _buildPerfumeOption(
                              ctx: ctx,
                              id: null,
                              label: 'Default / Tanpa Parfum',
                              subtitle: 'Tidak menggunakan parfum tambahan',
                              icon: Icons.do_not_disturb_alt_rounded,
                              iconBg: const Color(0xFFF1F5F9),
                              iconColor: const Color(0xFF94A3B8),
                              isSelected: _selectedPerfumeId == null,
                            ),
                            const SizedBox(height: 8),
                            if (filtered.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'Parfum tidak ditemukan',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              )
                            else
                              ...filtered.map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildPerfumeOption(
                                    ctx: ctx,
                                    id: p.id,
                                    label: p.name,
                                    subtitle: 'Parfum pilihan',
                                    icon: Icons.water_drop_rounded,
                                    iconBg: const Color(0xFFFDF4FF),
                                    iconColor: const Color(0xFF9333EA),
                                    isSelected: _selectedPerfumeId == p.id,
                                  ),
                                ),
                              ),
                          ],
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

  Widget _buildPerfumeOption({
    required BuildContext ctx,
    required String? id,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => _selectedPerfumeId = id);
          Navigator.pop(ctx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF5F0FF)
                : const Color(0xFFFAFBFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF9333EA)
                  : const Color(0xFFE8EEFF),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF9333EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerfumeSection() {
    final perfumeState = ref.watch(perfumeControllerProvider);

    final selectedName = perfumeState.maybeWhen(
      data: (perfumes) {
        if (_selectedPerfumeId == null) return null;
        try {
          return perfumes.firstWhere((p) => p.id == _selectedPerfumeId).name;
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

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
            data: (perfumes) => GestureDetector(
              onTap: () => _showPerfumeModal(perfumes),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedPerfumeId != null
                        ? const Color(0xFF9333EA)
                        : const Color(0xFFE2E8F0),
                    width: _selectedPerfumeId != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedPerfumeId != null
                            ? const Color(0xFFFDF4FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: _selectedPerfumeId != null
                            ? const Color(0xFF9333EA)
                            : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedName ?? 'Default / Tanpa Parfum',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedPerfumeId != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedPerfumeId != null
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    if (_selectedPerfumeId != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedPerfumeId = null),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.close_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                  ],
                ),
              ),
            ),
            loading: () => Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF9333EA),
                  ),
                ),
              ),
            ),
            error: (e, s) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gagal memuat parfum',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F62FE), Color(0xFF4F8EFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F62FE).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Layanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
            GestureDetector(
              onTap: _showEstimatedDateModal,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFD0FF)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F62FE),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimasi Selesai',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat(
                              'EEEE, d MMM yyyy • HH:mm',
                              'id_ID',
                            ).format(_estimatedCompletionDate),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_customCompletionDate != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _customCompletionDate = null),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.close_rounded,
                            color: Color(0xFF3B82F6),
                            size: 16,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.edit_calendar_rounded,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                  ],
                ),
              ),
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
            if (_paymentStatus == 'PARTIAL') ...[
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

class _DatePreset {
  final String label;
  final IconData icon;
  final DateTime date;
  final Color color;
  final Color bgColor;

  const _DatePreset(this.label, this.icon, this.date, this.color, this.bgColor);
}
