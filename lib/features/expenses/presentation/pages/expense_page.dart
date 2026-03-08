import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';
import '../../../outlet/presentation/controllers/outlet_controller.dart';
import '../widgets/add_expense_dialog.dart';

class ExpensePage extends ConsumerStatefulWidget {
  const ExpensePage({super.key});

  @override
  ConsumerState<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends ConsumerState<ExpensePage> {
  String? selectedOutletId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final outletsState = ref.read(outletControllerProvider);
    if (outletsState.hasValue && outletsState.value!.isNotEmpty) {
      final firstOutletId = outletsState.value!.first.id;
      setState(() {
        selectedOutletId = firstOutletId;
      });
      ref.read(expenseControllerProvider.notifier).loadExpenses(firstOutletId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseControllerProvider);
    final outletsState = ref.watch(outletControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran Operasional'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: outletsState.when(
              data: (outlets) {
                if (outlets.isEmpty) return const SizedBox();
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  initialValue: selectedOutletId,
                  items: outlets.map((outlet) {
                    return DropdownMenuItem(
                      value: outlet.id,
                      child: Text(outlet.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedOutletId = value;
                      });
                      ref
                          .read(expenseControllerProvider.notifier)
                          .loadExpenses(value);
                    }
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Gagal memuat cabang'),
            ),
          ),
        ),
      ),
      body: expenseState.when(
        data: (expenses) {
          if (selectedOutletId == null) {
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
                    if (selectedOutletId != null) {
                      await ref
                          .read(expenseControllerProvider.notifier)
                          .loadExpenses(selectedOutletId!);
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
                            '${expense.category} • ${DateFormat('dd MMM yyyy').format(expense.expenseDate)}',
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
        onPressed: selectedOutletId != null
            ? () {
                showDialog(
                  context: context,
                  builder: (ctx) =>
                      AddExpenseDialog(outletId: selectedOutletId!),
                );
              }
            : null,
        backgroundColor: selectedOutletId != null
            ? Theme.of(context).colorScheme.error
            : Colors.grey,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
