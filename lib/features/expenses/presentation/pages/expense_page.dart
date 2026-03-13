import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';
import '../../../outlet/presentation/controllers/active_outlet_controller.dart';
import '../widgets/add_expense_dialog.dart';

class ExpensePage extends ConsumerStatefulWidget {
  const ExpensePage({super.key});

  @override
  ConsumerState<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends ConsumerState<ExpensePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final activeOutletState = ref.read(activeOutletProvider);
    if (activeOutletState.hasValue && activeOutletState.value != null) {
      ref.read(expenseControllerProvider.notifier).loadExpenses(activeOutletState.value!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseControllerProvider);
    final activeOutletState = ref.watch(activeOutletProvider);

    // Provide a continuous listen in case active outlet changes
    ref.listen(activeOutletProvider, (previous, next) {
      if (next.hasValue && next.value != null && next.value?.id != previous?.value?.id) {
        ref.read(expenseControllerProvider.notifier).loadExpenses(next.value!.id);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran Operasional'),
      ),
      body: expenseState.when(
        data: (expenses) {
          if (activeOutletState.value == null) {
            return const Center(child: Text('Pilih cabang terlebih dahulu.'));
          }
          if (expenses.isEmpty) {
            return const Center(child: Text('Tidak ada catatan pengeluaran.'));
          }

          final formatter = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp',
            decimalDigits: 0,
          );
          final totalSatuBulan = expenses.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pengeluaran:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatter.format(totalSatuBulan),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (activeOutletState.value != null) {
                      await ref
                          .read(expenseControllerProvider.notifier)
                          .loadExpenses(activeOutletState.value!.id);
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Icon(
                              Icons.money_off,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            expense.expenseName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${expense.category} • ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(expense.expenseDate.toLocal())}',
                          ),
                          trailing: Text(
                            formatter.format(expense.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Gagal memuat pengeluaran: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: activeOutletState.value != null
            ? () {
                showDialog(
                  context: context,
                  builder: (ctx) =>
                      AddExpenseDialog(outletId: activeOutletState.value!.id),
                );
              }
            : null,
        backgroundColor: activeOutletState.value != null
            ? Theme.of(context).colorScheme.error
            : Colors.grey,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
