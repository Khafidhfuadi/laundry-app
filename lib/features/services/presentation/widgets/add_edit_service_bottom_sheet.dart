import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/service_entity.dart';
import '../controllers/service_controller.dart';

Future<void> showAddEditServiceBottomSheet(
  BuildContext context, {
  ServiceEntity? service,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AddEditServiceBottomSheet(service: service),
  );
}

Future<ServiceVariantEntity?> showVariantBottomSheet(
  BuildContext context, {
  ServiceVariantEntity? variant,
}) {
  return showModalBottomSheet<ServiceVariantEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _VariantBottomSheet(variant: variant),
  );
}

class AddEditServiceBottomSheet extends ConsumerStatefulWidget {
  final ServiceEntity? service;
  const AddEditServiceBottomSheet({super.key, this.service});

  @override
  ConsumerState<AddEditServiceBottomSheet> createState() =>
      _AddEditServiceBottomSheetState();
}

class _AddEditServiceBottomSheetState
    extends ConsumerState<AddEditServiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _itemNameController;
  late String _selectedCategory;

  List<ServiceVariantEntity> _variants = [];
  bool _isLoading = false;

  final Set<String> _selectedProcesses = {};

  static const _primary = Color(0xFF0F62FE);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  static const _availableProcesses = ['Cuci', 'Kering', 'Setrika'];
  static const _availableCategories = [
    'Layanan Umum',
    'Laundry',
    'Dry Clean',
    'Sepatu',
    'Tas',
    'Karpet',
    'Bedcover',
  ];

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;

    _itemNameController = TextEditingController(text: s?.name ?? '');
    final initialCategory = s?.categoryName.trim() ?? '';
    _selectedCategory = initialCategory.isEmpty
        ? 'Layanan Umum'
        : initialCategory;

    if (s?.processType != null && s!.processType.isNotEmpty) {
      _selectedProcesses.addAll(
        s.processType
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    }

    if (s != null) {
      _variants = List.from(s.variants);
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProcesses.isEmpty) {
      _showSnackbar(
        'Pilih minimal satu proses pengerjaan',
        const Color(0xFFF59E0B),
        Icons.warning_amber_rounded,
      );
      return;
    }

    if (_variants.isEmpty) {
      _showSnackbar(
        'Tambahkan minimal satu jenis produk (varian)',
        const Color(0xFFEF4444),
        Icons.error_outline,
      );
      return;
    }

    setState(() => _isLoading = true);

    final processTypeStr = _selectedProcesses.join(', ');

    bool success;
    if (_isEdit) {
      final updated = widget.service!.copyWith(
        name: _itemNameController.text.trim(),
        categoryName: _selectedCategory,
        processType: processTypeStr,
        variants: _variants,
      );
      success = await ref
          .read(serviceControllerProvider.notifier)
          .updateService(updated);
    } else {
      success = await ref
          .read(serviceControllerProvider.notifier)
          .createService(
            categoryName: _selectedCategory,
            itemName: _itemNameController.text.trim(),
            processType: processTypeStr,
            variants: _variants,
          );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        _showSnackbar(
          _isEdit
              ? 'Layanan berhasil diperbarui'
              : 'Layanan berhasil ditambahkan',
          const Color(0xFF10B981),
          Icons.check_circle_outline,
        );
      } else {
        setState(() => _isLoading = false);
        _showSnackbar(
          _isEdit ? 'Gagal memperbarui layanan' : 'Gagal menambahkan layanan',
          const Color(0xFFEF4444),
          Icons.error_outline,
        );
      }
    }
  }

  void _showSnackbar(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _toggleProcess(String process) {
    setState(() {
      if (_selectedProcesses.contains(process)) {
        _selectedProcesses.remove(process);
      } else {
        _selectedProcesses.add(process);
      }
    });
  }

  Future<void> _onAddVariant() async {
    final newVariant = await showVariantBottomSheet(context);
    if (newVariant != null) {
      setState(() {
        _variants.add(newVariant);
      });
    }
  }

  Future<void> _onEditVariant(int index) async {
    final updatedVariant = await showVariantBottomSheet(
      context,
      variant: _variants[index],
    );
    if (updatedVariant != null) {
      setState(() {
        _variants[index] = updatedVariant;
      });
    }
  }

  void _onRemoveVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
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
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Edit Layanan' : 'Tambah Layanan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      _isEdit
                          ? 'Ubah detail layanan ${widget.service?.name}'
                          : 'Isi detail produk dan layanan baru',
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Form digulir
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Parent: (selalu tampil)
                    _buildField(
                      controller: _itemNameController,
                      label: 'Nama Produk',
                      hint: 'Misal: Kiloan, Boneka, Sepatu',
                      icon: Icons.label_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(
                      label: 'Kategori Layanan',
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Proses',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableProcesses.map((process) {
                        final isSelected = _selectedProcesses.contains(process);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(process),
                          onSelected: (_) => _toggleProcess(process),
                          selectedColor: const Color(0xFFE0E7FF),
                          checkmarkColor: _primary,
                          labelStyle: TextStyle(
                            color: isSelected ? _primary : _textMuted,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? _primary
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: _border),
                    const SizedBox(height: 16),

                    const Text(
                      'Jenis Produk / Varian',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List of Variants Summary
                    if (_variants.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Text(
                          'Belum ada jenis produk. Tambahkan jenis produk (varian) untuk layanan ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: _textMuted),
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _variants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _buildVariantSummaryCard(i),
                      ),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _onAddVariant,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Jenis Produk'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: _textMuted,
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Simpan Perubahan' : 'Simpan Layanan',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSummaryCard(int index) {
    final v = _variants[index];
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    String formatHours(int hours) {
      if (hours >= 24 && hours % 24 == 0) {
        return '${hours ~/ 24} Hari';
      }
      return '$hours Jam';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          v.variantName.isEmpty ? 'Umum' : v.variantName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _textDark,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: _textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${formatter.format(v.price)} / ${v.unitType}',
                    style: const TextStyle(color: _textMuted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: _textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatHours(v.estimatedHours),
                    style: const TextStyle(color: _textMuted, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: _primary, size: 20),
              onPressed: () => _onEditVariant(index),
              tooltip: 'Edit Varian',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              onPressed: () => _onRemoveVariant(index),
              tooltip: 'Hapus Varian',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: const Color(0xFF94A3B8), size: 18)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines == 1 ? 12 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown({
    required String label,
    required IconData icon,
  }) {
    final categoryItems = {
      ..._availableCategories,
      if (_selectedCategory.trim().isNotEmpty) _selectedCategory,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          isExpanded: true,
          items: categoryItems
              .map(
                (category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedCategory = value);
          },
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _VariantBottomSheet extends StatefulWidget {
  final ServiceVariantEntity? variant;
  const _VariantBottomSheet({this.variant});

  @override
  State<_VariantBottomSheet> createState() => _VariantBottomSheetState();
}

class _VariantBottomSheetState extends State<_VariantBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _variantController;
  late final TextEditingController _priceController;
  late final TextEditingController _hoursController;
  late final TextEditingController _customUnitController;
  late final TextEditingController _notesController;

  String _unitType = 'Kg';
  String _timeUnitType = 'Hari';

  static const _primary = Color(0xFF0F62FE);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  static const _unitTypes = ['Kg', 'Pcs', 'Meter', 'Set', 'Isi Sendiri'];
  static const _timeUnitTypes = ['Jam', 'Hari'];

  bool get _isCustomUnit => _unitType == 'Isi Sendiri';

  @override
  void initState() {
    super.initState();
    final v = widget.variant;
    _variantController = TextEditingController(text: v?.variantName ?? '');
    _priceController = TextEditingController(
      text: v != null ? v.price.toInt().toString() : '',
    );

    int displayHours = v?.estimatedHours ?? 24;
    if (v == null) {
      _timeUnitType = 'Hari';
    } else if (v.estimatedHours >= 24 && v.estimatedHours % 24 == 0) {
      _timeUnitType = 'Hari';
      displayHours = v.estimatedHours ~/ 24;
    } else {
      _timeUnitType = 'Jam';
    }
    _hoursController = TextEditingController(
      text: v != null ? displayHours.toString() : '',
    );

    _customUnitController = TextEditingController();
    if (v != null && !_unitTypes.contains(v.unitType)) {
      _unitType = 'Isi Sendiri';
      _customUnitController.text = v.unitType;
    } else {
      _unitType = v?.unitType ?? 'Kg';
    }

    _notesController = TextEditingController(text: v?.notes ?? '');
  }

  @override
  void dispose() {
    _variantController.dispose();
    _priceController.dispose();
    _hoursController.dispose();
    _customUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final finalUnit = _isCustomUnit
        ? _customUnitController.text.trim()
        : _unitType;
    int totalEstimatedHours = int.tryParse(_hoursController.text) ?? 24;
    if (_timeUnitType == 'Hari') {
      totalEstimatedHours *= 24;
    }

    final newVariant = ServiceVariantEntity(
      id: widget.variant?.id ?? '',
      serviceId: widget.variant?.serviceId ?? '',
      variantName: _variantController.text.trim(),
      unitType: finalUnit,
      price: double.tryParse(_priceController.text) ?? 0,
      serviceType: 'Reguler',
      estimatedHours: totalEstimatedHours,
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, newVariant);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
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
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.variant != null
                      ? Icons.edit_outlined
                      : Icons.add_circle_outline,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.variant != null ? 'Edit Varian' : 'Tambah Varian',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const Text(
                      'Detail harga, satuan, form varian',
                      style: TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Form digulir
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      controller: _variantController,
                      label: 'Nama Jenis Produk',
                      hint: 'Misal: Reguler, Express, Boneka Besar',
                      icon: Icons.tune_outlined,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdown(
                                label: 'Satuan',
                                value: _unitType,
                                items: _unitTypes,
                                icon: Icons.straighten_outlined,
                                onChanged: (v) =>
                                    setState(() => _unitType = v!),
                              ),
                              if (_isCustomUnit) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _customUnitController,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _textDark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Tulis satuan',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: _primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  validator: (v) =>
                                      _isCustomUnit && (v == null || v.isEmpty)
                                      ? 'Isi'
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildField(
                            controller: _priceController,
                            label: 'Harga (Rp)',
                            hint: '0',
                            icon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Wajib disii'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _hoursController,
                            label: 'Lama Pengerjaan',
                            hint: 'Misal: 2',
                            icon: Icons.schedule_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Wajib' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 150,
                          child: _buildDropdown(
                            label: 'Waktu',
                            value: _timeUnitType,
                            items: _timeUnitTypes,
                            icon: Icons.timer_outlined,
                            onChanged: (v) =>
                                setState(() => _timeUnitType = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      controller: _notesController,
                      label: 'Keterangan Layanan (Opsional)',
                      hint: 'Misal: Harga bisa berubah tergantung noda',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: _textMuted,
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Varian',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: const Color(0xFF94A3B8), size: 18)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines == 1 ? 12 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          items: items
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    t,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
