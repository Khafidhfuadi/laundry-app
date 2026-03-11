import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/service_entity.dart';
import '../controllers/service_controller.dart';

class ServicePage extends ConsumerStatefulWidget {
  const ServicePage({super.key});

  @override
  ConsumerState<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends ConsumerState<ServicePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

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
      final matchQuery = _searchQuery.isEmpty ||
          s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat =
          _selectedCategory == null || s.categoryName == _selectedCategory;
      return matchQuery && matchCat;
    }).toList();
  }

  Map<String, List<ServiceEntity>> _groupByCategory(List<ServiceEntity> list) {
    final map = <String, List<ServiceEntity>>{};
    for (final s in list) {
      map.putIfAbsent(s.categoryName, () => []).add(s);
    }
    return map;
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
                            data: (services) => Text(
                              '${services.length} layanan tersedia',
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
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(serviceControllerProvider.notifier)
                              .refresh();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.refresh_outlined,
                            color: _textMuted,
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
                        hintText: 'Cari nama layanan atau kategori...',
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
                  final categories =
                      allServices.map((s) => s.categoryName).toSet().toList()
                        ..sort();

                  final filtered = _filtered(allServices);
                  final grouped = _groupByCategory(filtered);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category filter chips
                      if (categories.isNotEmpty)
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildChip('Semua', null, categories),
                              ...categories.map(
                                (cat) => _buildChip(cat, cat, categories),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // List
                      Expanded(
                        child: filtered.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: _primaryColor,
                                onRefresh: () async {
                                  await ref
                                      .read(serviceControllerProvider.notifier)
                                      .refresh();
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    20,
                                  ),
                                  itemCount: grouped.keys.length,
                                  itemBuilder: (context, index) {
                                    final cat =
                                        grouped.keys.toList()[index];
                                    final items = grouped[cat]!;
                                    return _buildCategorySection(cat, items);
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
                        onPressed: () {
                          ref
                              .read(serviceControllerProvider.notifier)
                              .refresh();
                        },
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

  Widget _buildChip(
      String label, String? value, List<String> allCategories) {
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

  Widget _buildCategorySection(
      String category, List<ServiceEntity> services) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Color per category
    final categoryColors = <String, List<Color>>{
      'Laundry': [const Color(0xFF0F62FE), const Color(0xFFE0E7FF)],
      'Dry Clean': [const Color(0xFF8B5CF6), const Color(0xFFEDE9FE)],
      'Setrika': [const Color(0xFFF97316), const Color(0xFFFFEDD5)],
      'Sepatu': [const Color(0xFF10B981), const Color(0xFFD1FAE5)],
      'Karpet': [const Color(0xFFEC4899), const Color(0xFFFCE7F3)],
    };
    final colors = categoryColors[category] ??
        [const Color(0xFF64748B), const Color(0xFFF1F5F9)];
    final iconColor = colors[0];
    final iconBg = colors[1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: iconColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${services.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Service cards
        ...services.map((s) => _buildServiceCard(s, iconColor, iconBg, formatter)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildServiceCard(
    ServiceEntity service,
    Color iconColor,
    Color iconBg,
    NumberFormat formatter,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_laundry_service,
                  color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTag(
                        service.serviceType,
                        service.serviceType == 'Express'
                            ? const Color(0xFFFFEDD5)
                            : const Color(0xFFE0E7FF),
                        service.serviceType == 'Express'
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF0F62FE),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.schedule,
                          size: 12, color: _textLight),
                      const SizedBox(width: 3),
                      Text(
                        '${service.estimatedHours} jam',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(service.price.toInt()),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                Text(
                  '/ ${service.unitType}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textLight,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
            'Coba ubah kata kunci atau filter kategori.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'laundry':
        return Icons.local_laundry_service;
      case 'dry clean':
        return Icons.dry_cleaning;
      case 'setrika':
        return Icons.iron;
      case 'sepatu':
        return Icons.workspace_premium;
      case 'karpet':
        return Icons.texture;
      default:
        return Icons.category_outlined;
    }
  }
}
