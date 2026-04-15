import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/custom_bottom_nav.dart';
import '../../domain/entities/expense_entity.dart';
import '../controllers/expense_controller.dart';
import '../../../outlet/presentation/controllers/active_outlet_controller.dart';
import '../widgets/add_expense_dialog.dart';

class ExpensePage extends ConsumerStatefulWidget {
  const ExpensePage({super.key});

  @override
  ConsumerState<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends ConsumerState<ExpensePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _primaryColor = Color(0xFF0F62FE);
  static const _bgColor = Color(0xFFF8F9FA);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);
  static const _textLight = Color(0xFF94A3B8);
  static const _expenseColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final activeOutletState = ref.read(activeOutletProvider);
    if (activeOutletState.hasValue && activeOutletState.value != null) {
      ref
          .read(expenseControllerProvider.notifier)
          .loadExpenses(activeOutletState.value!.id);
    }
  }

  List<ExpenseEntity> _filteredExpenses(List<ExpenseEntity> expenses) {
    if (_searchQuery.isEmpty) return expenses;

    final query = _searchQuery.toLowerCase();
    return expenses.where((item) {
      return item.expenseName.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.notes.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseControllerProvider);
    final activeOutletState = ref.watch(activeOutletProvider);

    ref.listen(activeOutletProvider, (previous, next) {
      if (next.hasValue &&
          next.value != null &&
          next.value?.id != previous?.value?.id) {
        ref
            .read(expenseControllerProvider.notifier)
            .loadExpenses(next.value!.id);
      }
    });

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: _bgColor,
      body: expenseState.when(
        data: (expenses) {
          if (activeOutletState.value == null) {
            return const Center(
              child: Text(
                'Pilih cabang terlebih dahulu.',
                style: TextStyle(color: _textMuted),
              ),
            );
          }

          final filteredExpenses = _filteredExpenses(expenses);
          final totalExpenses = expenses.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                'Pengeluaran',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${expenses.length} catatan di ${activeOutletState.value!.name}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              showAddExpenseBottomSheet(
                                context,
                                outletId: activeOutletState.value!.id,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _expenseColor,
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                color: _expenseColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Pengeluaran',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    formatter.format(totalExpenses),
                                    style: const TextStyle(
                                      color: _textDark,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
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
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${expenses.length} item',
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textDark,
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Cari nama, kategori, atau catatan...',
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
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? _buildEmptyState(isSearching: _searchQuery.isNotEmpty)
                      : RefreshIndicator(
                          color: _primaryColor,
                          onRefresh: () async {
                            if (activeOutletState.value != null) {
                              await ref
                                  .read(expenseControllerProvider.notifier)
                                  .loadExpenses(activeOutletState.value!.id);
                            }
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            itemCount: filteredExpenses.length,
                            itemBuilder: (context, index) {
                              final expense = filteredExpenses[index];
                              return _buildExpenseCard(
                                formatter: formatter,
                                expense: expense,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    color: _expenseColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal memuat pengeluaran',
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
                    if (activeOutletState.value != null) {
                      ref
                          .read(expenseControllerProvider.notifier)
                          .loadExpenses(activeOutletState.value!.id);
                    }
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
      floatingActionButton: const CustomBottomNavFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 3),
    );
  }

  Widget _buildEmptyState({required bool isSearching}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
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
                Icons.receipt_long_outlined,
                size: 40,
                color: _expenseColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Tidak ada data yang cocok'
                  : 'Belum ada catatan pengeluaran',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Coba kata kunci lain untuk pencarian Anda.'
                  : 'Tambahkan pengeluaran pertama untuk mulai mencatat operasional.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard({
    required NumberFormat formatter,
    required ExpenseEntity expense,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.money_off_outlined,
              color: _expenseColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.expenseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.category} • ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(expense.expenseDate.toLocal())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatter.format(expense.amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _expenseColor,
            ),
          ),
        ],
      ),
    );
  }
}
