class ExpenseEntity {
  final String id;
  final String outletId;
  final String expenseName;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String notes;

  const ExpenseEntity({
    required this.id,
    required this.outletId,
    required this.expenseName,
    required this.category,
    required this.amount,
    required this.expenseDate,
    required this.notes,
  });

  factory ExpenseEntity.fromJson(Map<String, dynamic> json) {
    return ExpenseEntity(
      id: json['id'] as String,
      outletId: json['outlet_id'] as String,
      expenseName: json['expense_name'] as String,
      category: json['category'] as String? ?? 'Operasional',
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date'] as String),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'outlet_id': outletId,
      'expense_name': expenseName,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'notes': notes,
    };
  }
}
