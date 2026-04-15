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
  String _selectedPeriod = 'Semua';
  String _selectedCategory = 'Semua';

  static const _periodOptions = ['Semua', 'Minggu ini', 'Bulan ini'];

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

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  bool _matchesPeriod(DateTime expenseDate) {
    if (_selectedPeriod == 'Semua') return true;

    final now = DateTime.now();
    final localDate = expenseDate.toLocal();

    if (_selectedPeriod == 'Minggu ini') {
      final startWeek = _startOfWeek(now);
      final endWeek = startWeek.add(const Duration(days: 7));
      return !localDate.isBefore(startWeek) && localDate.isBefore(endWeek);
    }

    if (_selectedPeriod == 'Bulan ini') {
      return localDate.year == now.year && localDate.month == now.month;
    }

    return true;
  }

  List<ExpenseEntity> _applyFilters(List<ExpenseEntity> expenses) {
    final query = _searchQuery.trim().toLowerCase();

    return expenses.where((item) {
      final isMatchQuery =
          query.isEmpty ||
          item.expenseName.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.notes.toLowerCase().contains(query);

      final isMatchCategory =
          _selectedCategory == 'Semua' || item.category == _selectedCategory;

      final isMatchPeriod = _matchesPeriod(item.expenseDate);

      return isMatchQuery && isMatchCategory && isMatchPeriod;
    }).toList()..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  ({double currentWeek, double previousWeek, double percentage, bool isUp})
  _weeklyComparison(List<ExpenseEntity> expenses) {
    final now = DateTime.now();
    final startCurrentWeek = _startOfWeek(now);
    final startNextWeek = startCurrentWeek.add(const Duration(days: 7));
    final startPreviousWeek = startCurrentWeek.subtract(
      const Duration(days: 7),
    );

    double currentWeek = 0;
    double previousWeek = 0;

    for (final expense in expenses) {
      final expenseDate = expense.expenseDate.toLocal();
      if (!expenseDate.isBefore(startCurrentWeek) &&
          expenseDate.isBefore(startNextWeek)) {
        currentWeek += expense.amount;
      } else if (!expenseDate.isBefore(startPreviousWeek) &&
          expenseDate.isBefore(startCurrentWeek)) {
        previousWeek += expense.amount;
      }
    }

    final difference = currentWeek - previousWeek;
    final percentage = previousWeek == 0
        ? (currentWeek == 0 ? 0.0 : 100.0)
        : (difference / previousWeek) * 100;

    return (
      currentWeek: currentWeek,
      previousWeek: previousWeek,
      percentage: percentage,
      isUp: difference >= 0,
    );
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

          final availableCategories = {
            for (final expense in expenses) expense.category,
          }.toList()..sort();
          final filteredExpenses = _applyFilters(expenses);
          final weeklyStats = _weeklyComparison(expenses);
          final isFilterActive =
              _searchQuery.isNotEmpty ||
              _selectedPeriod != 'Semua' ||
              _selectedCategory != 'Semua';

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
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pengeluaran',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${expenses.length} catatan di minggu ini',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Material(
                              color: _expenseColor,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  showAddExpenseBottomSheet(
                                    context,
                                    outletId: activeOutletState.value!.id,
                                  );
                                },
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 22,
                                ),
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
                                    'Total Pengeluaran Minggu Ini',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    formatter.format(weeklyStats.currentWeek),
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
                                color: weeklyStats.isUp
                                    ? const Color(0xFFFFE4E6)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${weeklyStats.isUp ? '+' : ''}${weeklyStats.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: weeklyStats.isUp
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF15803D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weeklyStats.previousWeek == 0 &&
                                weeklyStats.currentWeek > 0
                            ? 'Belum ada data pada minggu lalu untuk perbandingan.'
                            : weeklyStats.previousWeek == 0
                            ? 'Belum ada pengeluaran pada minggu ini.'
                            : '${weeklyStats.percentage.abs().toStringAsFixed(1)}% ${weeklyStats.isUp ? 'lebih tinggi' : 'lebih rendah'} dibanding minggu lalu',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
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
                                  hintText: 'Cari pengeluaran...',
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
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: PopupMenuButton<String>(
                              tooltip: 'Filter pengeluaran',
                              onSelected: (value) {
                                if (value == 'reset') {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedPeriod = 'Semua';
                                    _selectedCategory = 'Semua';
                                  });
                                  return;
                                }

                                if (value.startsWith('period:')) {
                                  setState(
                                    () => _selectedPeriod = value.replaceFirst(
                                      'period:',
                                      '',
                                    ),
                                  );
                                  return;
                                }

                                if (value.startsWith('category:')) {
                                  setState(
                                    () => _selectedCategory = value
                                        .replaceFirst('category:', ''),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<String>(
                                  enabled: false,
                                  value: 'period-label',
                                  child: Text('Periode'),
                                ),
                                ..._periodOptions.map(
                                  (period) => CheckedPopupMenuItem<String>(
                                    value: 'period:$period',
                                    checked: _selectedPeriod == period,
                                    child: Text(period),
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem<String>(
                                  enabled: false,
                                  value: 'category-label',
                                  child: Text('Kategori'),
                                ),
                                CheckedPopupMenuItem<String>(
                                  value: 'category:Semua',
                                  checked: _selectedCategory == 'Semua',
                                  child: const Text('Semua Kategori'),
                                ),
                                ...availableCategories.map(
                                  (category) => CheckedPopupMenuItem<String>(
                                    value: 'category:$category',
                                    checked: _selectedCategory == category,
                                    child: Text(category),
                                  ),
                                ),
                                if (isFilterActive) ...[
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'reset',
                                    child: Text('Reset Filter'),
                                  ),
                                ],
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: isFilterActive
                                          ? _primaryColor
                                          : _textMuted,
                                    ),
                                    if (isFilterActive) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Aktif',
                                        style: TextStyle(
                                          color: _primaryColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
            '-${formatter.format(expense.amount)}',
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
