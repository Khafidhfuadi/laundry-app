import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/service_controller.dart';

class ServicePage extends ConsumerWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceState = ref.watch(serviceControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Katalog Layanan')),
      body: serviceState.when(
        data: (services) {
          if (services.isEmpty) {
            return const Center(
              child: Text('Belum ada data layanan tersedia.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(serviceControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.local_offer,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      service.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${service.categoryName} • ${service.serviceType}',
                        ),
                        Text('Estimasi: ${service.estimatedHours} Jam'),
                      ],
                    ),
                    trailing: Text(
                      'Rp ${service.price.toInt()} / ${service.unitType}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Gagal memuat layanan: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Akan membuka modal tambah layanan (untuk admin)
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Layanan'),
      ),
    );
  }
}
