import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/transaction_controller.dart';

class TransactionPage extends ConsumerWidget {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Transaksi')),
      body: transactionState.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('Belum ada transaksi saat ini.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref
                .read(transactionControllerProvider.notifier)
                .loadTransactions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final trx = transactions[index];
                final formatter = NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp',
                  decimalDigits: 0,
                );

                // Menentukan warna badge status
                Color statusColor = Colors.blue;
                String statusText = 'Proses';
                if (trx.status == 'READY') {
                  statusColor = Colors.green;
                  statusText = 'Siap Diambil';
                } else if (trx.status == 'PICKED_UP') {
                  statusColor = Colors.grey;
                  statusText = 'Selesai';
                }

                // Menentukan status bayar
                String paymentText = 'Belum Bayar';
                Color paymentColor = Colors.red;
                if (trx.paymentStatus == 'PAID') {
                  paymentText = 'Lunas';
                  paymentColor = Colors.green;
                } else if (trx.paymentStatus == 'PARTIAL') {
                  paymentText = 'Sebagian';
                  paymentColor = Colors.orange;
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              trx.transactionCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              trx.customer?.name ?? 'Tanpa Nama',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${formatter.format(trx.totalPrice)} • $paymentText',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: paymentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (trx.status == 'PROCESS')
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(
                                        transactionControllerProvider.notifier,
                                      )
                                      .updateStatus(trx.id, 'READY');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: const Text('Siap Diambil'),
                              ),
                            if (trx.status == 'READY')
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(
                                        transactionControllerProvider.notifier,
                                      )
                                      .updateStatus(trx.id, 'PICKED_UP');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                                icon: const Icon(Icons.done_all, size: 18),
                                label: const Text('Selesaikan'),
                              ),
                          ],
                        ),
                      ],
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
            'Gagal memuat transaksi: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/transactions/add');
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Buat Transaksi'),
      ),
    );
  }
}
