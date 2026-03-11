import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/perfume_entity.dart';
import '../controllers/perfume_controller.dart';

class PerfumePage extends ConsumerStatefulWidget {
  const PerfumePage({super.key});

  @override
  ConsumerState<PerfumePage> createState() => _PerfumePageState();
}

class _PerfumePageState extends ConsumerState<PerfumePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _primaryColor = Color(0xFF0F62FE);
  static const _bgColor = Color(0xFFF8F9FA);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PerfumeEntity> _filtered(List<PerfumeEntity> all) {
    if (_searchQuery.isEmpty) return all;
    return all
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showAddEditDialog([PerfumeEntity? perfume]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: perfume?.name ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                perfume == null ? 'Tambah Parfum' : 'Edit Parfum',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                    fontSize: 18),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Wajib diisi'
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Nama Parfum',
                        hintText: 'Misal: Lavender',
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal',
                      style: TextStyle(color: _textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => isSaving = true);

                          final navigator = Navigator.of(ctx);
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);

                          final newPerfume = PerfumeEntity(
                            id: perfume?.id ?? '',
                            name: nameController.text.trim(),
                          );

                          bool success;
                          if (perfume == null) {
                            success = await ref
                                .read(perfumeControllerProvider.notifier)
                                .createPerfume(newPerfume);
                          } else {
                            success = await ref
                                .read(perfumeControllerProvider.notifier)
                                .updatePerfume(newPerfume);
                          }

                          if (success) {
                            navigator.pop();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(perfume == null
                                    ? 'Parfum berhasil ditambahkan'
                                    : 'Parfum berhasil diperbarui'),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            setState(() => isSaving = false);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Terjadi kesalahan'),
                                backgroundColor: Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(perfume == null ? 'Simpan' : 'Update',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(PerfumeEntity perfume) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Parfum',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: _textDark, fontSize: 18),
        ),
        content: Text(
          'Yakin ingin menghapus parfum ${perfume.name}? Transaksi sebelumnya '
          'yang menggunakan parfum ini mungkin akan kehilangan referensinya (null).',
          style: const TextStyle(
              fontSize: 14, color: _textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(perfumeControllerProvider.notifier)
                  .deletePerfume(perfume.id);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Parfum berhasil dihapus'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal menghapus parfum'),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Hapus',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfumeState = ref.watch(perfumeControllerProvider);

    return Scaffold(
      backgroundColor: _bgColor,
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
          'Kelola Parfum',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Add
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari parfum...',
                        hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            color: _textMuted, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: const Icon(Icons.close,
                                    color: Color(0xFF94A3B8), size: 18),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showAddEditDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: perfumeState.when(
              data: (allPerfumes) {
                final filtered = _filtered(allPerfumes);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.spa_outlined,
                            size: 64, color: _textMuted.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Belum ada data parfum'
                              : 'Tidak ditemukan parfum "$_searchQuery"',
                          style: const TextStyle(
                              color: _textMuted, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final perfume = filtered[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.water_drop_outlined,
                                color: _primaryColor, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              perfume.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _textDark),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showAddEditDialog(perfume),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.edit_outlined,
                                      size: 18, color: _textMuted),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _confirmDelete(perfume),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_outline,
                                      size: 18, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _primaryColor)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
