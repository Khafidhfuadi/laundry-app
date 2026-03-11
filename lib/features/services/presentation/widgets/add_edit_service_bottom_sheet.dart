import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late final TextEditingController _categoryController;
  late final TextEditingController _itemNameController;
  late final TextEditingController _variantController;
  late final TextEditingController _priceController;
  late final TextEditingController _hoursController;

  String _unitType = 'Kg';
  String _serviceType = 'Reguler';
  bool _isLoading = false;

  static const _primary = Color(0xFF0F62FE);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  static const _unitTypes = ['Kg', 'Pcs', 'Lembar', 'Pasang', 'Set'];
  static const _serviceTypes = ['Reguler', 'Express'];

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _categoryController = TextEditingController(text: s?.categoryName ?? '');
    _itemNameController = TextEditingController(text: s?.itemName ?? '');
    _variantController = TextEditingController(text: s?.variant ?? '');
    _priceController =
        TextEditingController(text: s != null ? s.price.toInt().toString() : '');
    _hoursController = TextEditingController(
        text: s != null ? s.estimatedHours.toString() : '');
    _unitType = s?.unitType ?? 'Kg';
    _serviceType = s?.serviceType ?? 'Reguler';
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _itemNameController.dispose();
    _variantController.dispose();
    _priceController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool success;
    if (_isEdit) {
      final updated = widget.service!.copyWith(
        variant: _variantController.text,
        unitType: _unitType,
        price: double.tryParse(_priceController.text) ?? 0,
        serviceType: _serviceType,
        estimatedHours: int.tryParse(_hoursController.text) ?? 24,
      );
      success = await ref
          .read(serviceControllerProvider.notifier)
          .updateService(updated);
    } else {
      success = await ref.read(serviceControllerProvider.notifier).createService(
            categoryName: _categoryController.text,
            itemName: _itemNameController.text,
            variant: _variantController.text,
            unitType: _unitType,
            price: double.tryParse(_priceController.text) ?? 0,
            serviceType: _serviceType,
            estimatedHours: int.tryParse(_hoursController.text) ?? 24,
          );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        _showSnackbar(
          _isEdit ? 'Layanan berhasil diperbarui' : 'Layanan berhasil ditambahkan',
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
            Text(msg),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
      child: SingleChildScrollView(
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
                Column(
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
                          ? 'Ubah detail layanan yang ada'
                          : 'Isi data layanan baru',
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori & Item Name (hanya saat tambah baru)
                  if (!_isEdit) ...[
                    _buildField(
                      controller: _categoryController,
                      label: 'Kategori',
                      hint: 'Misal: Laundry, Dry Clean, Setrika',
                      icon: Icons.category_outlined,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _itemNameController,
                      label: 'Nama Item',
                      hint: 'Misal: Pakaian, Sepatu, Karpet',
                      icon: Icons.label_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Varian
                  _buildField(
                    controller: _variantController,
                    label: 'Varian (Opsional)',
                    hint: 'Misal: Kilogram, Satuan',
                    icon: Icons.tune_outlined,
                  ),
                  const SizedBox(height: 12),

                  // Unit & Service Type row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Satuan',
                          value: _unitType,
                          items: _unitTypes,
                          icon: Icons.straighten_outlined,
                          onChanged: (v) => setState(() => _unitType = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Tipe',
                          value: _serviceType,
                          items: _serviceTypes,
                          icon: Icons.speed_outlined,
                          onChanged: (v) => setState(() => _serviceType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Harga & Estimasi row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildField(
                          controller: _priceController,
                          label: 'Harga (Rp)',
                          hint: '0',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _hoursController,
                          label: 'Estimasi (Jam)',
                          hint: '24',
                          icon: Icons.schedule_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
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
                            disabledBackgroundColor:
                                _primary.withOpacity(0.5),
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
                                  _isEdit ? 'Simpan Perubahan' : 'Tambah Layanan',
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
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
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
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
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
          value: value,
          items: items
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
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
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
