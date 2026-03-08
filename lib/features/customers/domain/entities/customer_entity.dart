class CustomerEntity {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String notes;
  final int totalTransactions;
  final DateTime? lastTransactionDate;
  final DateTime createdAt;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.notes,
    required this.totalTransactions,
    this.lastTransactionDate,
    required this.createdAt,
  });

  factory CustomerEntity.fromJson(Map<String, dynamic> json) {
    return CustomerEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      address: json['address'] ?? '',
      notes: json['notes'] ?? '',
      totalTransactions: json['total_transactions'] as int? ?? 0,
      lastTransactionDate: json['last_transaction_date'] != null
          ? DateTime.parse(json['last_transaction_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'address': address,
      'notes': notes,
      'total_transactions': totalTransactions,
      if (lastTransactionDate != null)
        'last_transaction_date': lastTransactionDate!.toIso8601String(),
    };
  }
}
