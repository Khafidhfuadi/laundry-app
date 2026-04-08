import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/service_entity.dart';
import '../controllers/service_controller.dart';
import '../widgets/add_edit_service_bottom_sheet.dart';

class ServicePage extends ConsumerStatefulWidget {
  const ServicePage({super.key});

  @override
  ConsumerState<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends ConsumerState<ServicePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  final Set<String> _expandedServiceIds = <String>{};

  static const _primaryColor = Color(0xFF0F62FE);
  static const _bgColor = Color(0xFFF8F9FA);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);
  static const _textLight = Color(0xFF94A3B8);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceEntity> _filtered(List<ServiceEntity> all) {
    return all.where((s) {
      final matchQuery =
          _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              s.categoryName != 'Layanan Umum');
      final matchCat =
          _selectedCategory == null || s.categoryName == _selectedCategory;
      return matchQuery && matchCat;
    }).toList();
  }

  bool get _isReorderEnabled {
    return _searchQuery.trim().isEmpty && _selectedCategory == null;
  }

  void _toggleExpanded(String serviceId) {
    setState(() {
      if (_expandedServiceIds.contains(serviceId)) {
        _expandedServiceIds.remove(serviceId);
      } else {
        _expandedServiceIds.add(serviceId);
      }
    });
  }

  Future<void> _onReorder(
    List<ServiceEntity> currentList,
    int oldIndex,
    int newIndex,
  ) async {
    if (!_isReorderEnabled) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final reordered = List<ServiceEntity>.from(currentList);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final success = await ref
        .read(serviceControllerProvider.notifier)
        .reorderServices(reordered);

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan urutan layanan'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _confirmDelete(ServiceEntity service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Layanan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textDark,
            fontSize: 18,
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: _textMuted,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Yakin ingin menghapus layanan '),
              TextSpan(
                text: service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const TextSpan(text: '? Tindakan ini tidak dapat dibatalkan.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(serviceControllerProvider.notifier)
          .deleteService(service.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  success
                      ? 'Layanan berhasil dihapus'
                      : 'Gagal menghapus layanan',
                ),
              ],
            ),
            backgroundColor: success
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // Fungsi utilitas format waktu
  String _formatHours(int hours) {
    if (hours >= 24 && hours % 24 == 0) {
      return '${hours ~/ 24} Hari';
    }
    return '$hours Jam';
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceControllerProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Katalog Layanan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          serviceState.when(
                            data: (s) => Text(
                              '${s.length} layanan tersedia',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            loading: () => const Text(
                              'Memuat...',
                              style: TextStyle(fontSize: 13, color: _textMuted),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      // Tombol Tambah
                      GestureDetector(
                        onTap: () => showAddEditServiceBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: _textDark),
                      decoration: InputDecoration(
                        hintText: 'Cari nama produk...',
                        hintStyle: const TextStyle(
                          color: _textLight,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: _textMuted,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: _textLight,
                                  size: 18,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: serviceState.when(
                data: (allServices) {
                  // Kita hide fitur kategori horizontal jika kategori default cuma Layanan Umum
                  final showCategories = allServices.any(
                    (s) => s.categoryName != 'Layanan Umum',
                  );
                  var categories = <String>[];
                  if (showCategories) {
                    categories = allServices
                        .map((s) => s.categoryName)
                        .toSet()
                        .toList();
                    categories.sort();
                  }

                  final filtered = _filtered(allServices);
                  final formatter = NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chips (optional)
                      if (categories.isNotEmpty) ...[
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildChip('Semua', null),
                              ...categories.map((cat) => _buildChip(cat, cat)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (filtered.isNotEmpty) _buildDragHint(),

                      Expanded(
                        child: filtered.isEmpty
                            ? _buildEmptyState()
                            : _isReorderEnabled
                            ? RefreshIndicator(
                                color: _primaryColor,
                                onRefresh: () async => ref
                                    .read(serviceControllerProvider.notifier)
                                    .refresh(),
                                child: ReorderableListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    20,
                                  ),
                                  itemCount: filtered.length,
                                  buildDefaultDragHandles: false,
                                  onReorder: (oldIndex, newIndex) =>
                                      _onReorder(filtered, oldIndex, newIndex),
                                  itemBuilder: (context, index) {
                                    return _buildAccordionItem(
                                      service: filtered[index],
                                      index: index,
                                      formatter: formatter,
                                      showDragHandle: true,
                                    );
                                  },
                                ),
                              )
                            : RefreshIndicator(
                                color: _primaryColor,
                                onRefresh: () async => ref
                                    .read(serviceControllerProvider.notifier)
                                    .refresh(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    20,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    return _buildAccordionItem(
                                      service: filtered[index],
                                      index: index,
                                      formatter: formatter,
                                      showDragHandle: false,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal memuat layanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: _textMuted),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => ref
                            .read(serviceControllerProvider.notifier)
                            .refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  Widget _buildChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildDragHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        _isReorderEnabled
            ? 'Tarik ikon handle untuk mengubah urutan katalog layanan.'
            : 'Urut drag dinonaktifkan saat filter atau pencarian aktif.',
        style: const TextStyle(
          fontSize: 12,
          color: _textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAccordionItem({
    required ServiceEntity service,
    required int index,
    required NumberFormat formatter,
    required bool showDragHandle,
  }) {
    final isExpanded = _expandedServiceIds.contains(service.id);

    return Container(
      key: ValueKey('service-${service.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _toggleExpanded(service.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  if (showDragHandle)
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.drag_handle,
                          color: _textLight,
                          size: 20,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${service.variants.length} varian',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showAddEditServiceBottomSheet(
                      context,
                      service: service,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: _textMuted,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _confirmDelete(service),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                children: service.variants
                    .map((v) => _buildServiceCard(service, v, formatter))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    ServiceEntity service,
    ServiceVariantEntity variant,
    NumberFormat formatter,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              variant.variantName.isEmpty
                                  ? 'Umum'
                                  : variant.variantName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (service.processType.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildTag(
                              service.processType,
                              const Color(0xFFF0FDF4),
                              const Color(0xFF16A34A),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: _textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatHours(variant.estimatedHours),
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (variant.notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notes,
                              size: 14,
                              color: _textLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                variant.notes,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textMuted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Price and Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.format(variant.price.toInt()),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    Text(
                      '/ ${variant.unitType}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final updatedVariant = await showVariantBottomSheet(
                              context,
                              variant: variant,
                            );
                            if (updatedVariant != null) {
                              final updatedService = service.copyWith(
                                variants: service.variants
                                    .map(
                                      (v) => v.id == variant.id
                                          ? updatedVariant
                                          : v,
                                    )
                                    .toList(),
                              );
                              ref
                                  .read(serviceControllerProvider.notifier)
                                  .updateService(updatedService);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: _textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.layers_outlined,
              size: 48,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Layanan Tidak Ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Klik tombol + untuk menambah layanan baru.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
