import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/outlet_controller.dart';
import '../widgets/add_outlet_dialog.dart';

class OutletPage extends ConsumerWidget {
  const OutletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outletState = ref.watch(outletControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Outlet')),
      body: outletState.when(
        data: (outlets) {
          if (outlets.isEmpty) {
            return const Center(child: Text('Belum ada data outlet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: outlets.length,
            itemBuilder: (context, index) {
              final outlet = outlets[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    outlet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(outlet.address),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: outlet.isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      outlet.isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        color: outlet.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    // Tindakan saat item di-tap (misalnya edit)
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Gagal memuat outlet: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const AddOutletDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Outlet'),
      ),
    );
  }
}
