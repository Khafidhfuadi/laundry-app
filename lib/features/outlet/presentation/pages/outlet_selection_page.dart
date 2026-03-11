import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/outlet_controller.dart';
import '../controllers/active_outlet_controller.dart';
import '../widgets/add_outlet_dialog.dart';

class OutletSelectionPage extends ConsumerStatefulWidget {
  const OutletSelectionPage({super.key});

  @override
  ConsumerState<OutletSelectionPage> createState() => _OutletSelectionPageState();
}

class _OutletSelectionPageState extends ConsumerState<OutletSelectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(outletControllerProvider.notifier).loadOutlets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final outletState = ref.watch(outletControllerProvider);
    final activeOutletState = ref.watch(activeOutletProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pilih Cabang Utama'),
        automaticallyImplyLeading: false, 
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: outletState.when(
        data: (outlets) {
          if (outlets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.store_mall_directory_outlined,
                    size: 80,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Anda belum memiliki cabang.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const AddOutletDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Cabang Pertama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Silakan pilih cabang mana yang ingin Anda kelola sesi ini. Anda dapat menggantinya lagi nanti melalui menu Profil.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: outlets.length,
                    itemBuilder: (context, index) {
                      final outlet = outlets[index];
                      final isActive = activeOutletState.value?.id == outlet.id;

                      return GestureDetector(
                        onTap: () async {
                          await ref.read(activeOutletProvider.notifier).setActiveOutlet(outlet);
                          if (context.mounted) {
                            context.go('/dashboard');
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFE8F0FE) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isActive ? const Color(0xFF0F62FE) : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF0F62FE) : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: isActive ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      outlet.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      outlet.address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF0F62FE),
                                ),
                            ],
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Gagal memuat cabang: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
