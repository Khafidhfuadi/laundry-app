import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/custom_bottom_nav.dart';
import '../controllers/transaction_controller.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Proses',
    'Siap Ambil',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionControllerProvider.notifier).loadTransactions();
    });

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionEntity> _getFilteredTransactions(
    List<TransactionEntity> allTransactions,
  ) {
    List<TransactionEntity> filtered = allTransactions;

    // Status Filter
    if (_selectedFilter == 'Proses') {
      filtered = filtered.where((t) => t.status == 'PROCESS').toList();
    } else if (_selectedFilter == 'Siap Ambil') {
      filtered = filtered.where((t) => t.status == 'READY').toList();
    } else if (_selectedFilter == 'Selesai') {
      filtered = filtered
          .where((t) => t.status == 'COMPLETED' || t.status == 'PICKED_UP')
          .toList();
    } else if (_selectedFilter == 'Dibatalkan') {
      filtered = filtered.where((t) => t.status == 'CANCELLED').toList();
    }

    // Search Query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((t) {
        final matchCode = t.transactionCode.toLowerCase().contains(query);
        final matchName =
            t.customer?.name.toLowerCase().contains(query) ?? false;
        return matchCode || matchName;
      }).toList();
    }

    return filtered;
  }

  int _getFilterCount(String filter, List<TransactionEntity> allTransactions) {
    if (filter == 'Semua') {
      return allTransactions.length;
    }
    if (filter == 'Proses') {
      return allTransactions.where((t) => t.status == 'PROCESS').length;
    }
    if (filter == 'Siap Ambil') {
      return allTransactions.where((t) => t.status == 'READY').length;
    }
    if (filter == 'Selesai') {
      return allTransactions
          .where((t) => t.status == 'COMPLETED' || t.status == 'PICKED_UP')
          .length;
    }
    if (filter == 'Dibatalkan') {
      return allTransactions.where((t) => t.status == 'CANCELLED').length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionControllerProvider);
    final allTransactions = transactionState.maybeWhen(
      data: (transactions) => transactions,
      orElse: () => <TransactionEntity>[],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFF0F62FE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Daftar Pesanan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Cari ID transaksi atau nama pelanggan...',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Filter Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  final count = _getFilterCount(filter, allTransactions);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0F62FE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            filter,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.24)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 4. Content Area
            Expanded(
              child: transactionState.when(
                data: (transactions) {
                  final filteredList = _getFilteredTransactions(transactions);

                  if (filteredList.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada transaksi.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(transactionControllerProvider.notifier)
                        .loadTransactions(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => context.push(
                            '/transactions/${filteredList[index].id}',
                          ),
                          child: _buildTransactionCard(filteredList[index]),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F62FE)),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Gagal: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Custom Bottom Nav Bar with FAB
      floatingActionButton: const CustomBottomNavFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildTransactionCard(TransactionEntity trx) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Status visual mapping
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    if (trx.status == 'PROCESS') {
      statusText = 'PROSES';
      statusColor = const Color(0xFF0F62FE);
      statusBgColor = const Color(0xFFE8F0FE);
      icon = Icons.sync;
      iconColor = const Color(0xFF0F62FE);
      iconBgColor = const Color(0xFFE8F0FE);
    } else if (trx.status == 'READY') {
      statusText = 'SIAP AMBIL';
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
      icon = Icons.check_circle_outline;
      iconColor = const Color(0xFFD97706);
      iconBgColor = const Color(0xFFFEF3C7);
    } else if (trx.status == 'CANCELLED') {
      statusText = 'DIBATALKAN';
      statusColor = const Color(0xFFDC2626);
      statusBgColor = const Color(0xFFFEE2E2);
      icon = Icons.cancel_outlined;
      iconColor = const Color(0xFFDC2626);
      iconBgColor = const Color(0xFFFEE2E2);
    } else {
      statusText = 'SELESAI';
      statusColor = const Color(0xFF059669);
      statusBgColor = const Color(0xFFD1FAE5);
      icon = Icons
          .inventory_2_outlined; // Re-use an icon matching completed/archived
      iconColor = const Color(0xFF059669);
      iconBgColor = const Color(0xFFD1FAE5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Top section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trx.customer?.name ?? 'Tanpa Nama',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Masuk: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(trx.createdAt.toLocal())}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Bottom section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL LAYANAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trx.items.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL HARGA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(trx.totalPrice),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
  }
}
