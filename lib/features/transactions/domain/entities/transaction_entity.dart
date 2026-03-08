import '../../../customers/domain/entities/customer_entity.dart';
import '../../../outlet/domain/entities/outlet_entity.dart';
import '../../../services/domain/entities/service_entity.dart';

class TransactionItemEntity {
  final String id;
  final String transactionId;
  final String serviceId;
  final double quantity;
  final double subtotal;
  final ServiceEntity? service; // Join data

  const TransactionItemEntity({
    required this.id,
    required this.transactionId,
    required this.serviceId,
    required this.quantity,
    required this.subtotal,
    this.service,
  });

  factory TransactionItemEntity.fromJson(Map<String, dynamic> json) {
    return TransactionItemEntity(
      id: json['id'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      serviceId: json['service_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      service: json['services'] != null
          ? ServiceEntity.fromJson(json['services'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (transactionId.isNotEmpty) 'transaction_id': transactionId,
      'service_id': serviceId,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}

class TransactionEntity {
  final String id;
  final String transactionCode;
  final String outletId;
  final String customerId;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final double paidAmount;
  final String notes;
  final DateTime estimatedCompletionDate;
  final DateTime createdAt;

  // Relations
  final CustomerEntity? customer;
  final OutletEntity? outlet;
  final List<TransactionItemEntity> items;

  const TransactionEntity({
    required this.id,
    required this.transactionCode,
    required this.outletId,
    required this.customerId,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.paidAmount,
    required this.notes,
    required this.estimatedCompletionDate,
    required this.createdAt,
    this.customer,
    this.outlet,
    this.items = const [],
  });

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'] as String,
      transactionCode: json['transaction_code'] as String? ?? '-',
      outletId: json['outlet_id'] as String,
      customerId: json['customer_id'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String? ?? 'PROCESS',
      paymentStatus: json['payment_status'] as String? ?? 'UNPAID',
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] ?? '',
      estimatedCompletionDate: DateTime.parse(
        json['estimated_completion_date'] as String,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      customer: json['customers'] != null
          ? CustomerEntity.fromJson(json['customers'])
          : null,
      outlet: json['outlets'] != null
          ? OutletEntity.fromJson(json['outlets'])
          : null,
      items: json['transaction_items'] != null
          ? (json['transaction_items'] as List)
                .map((e) => TransactionItemEntity.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (transactionCode.isNotEmpty) 'transaction_code': transactionCode,
      'outlet_id': outletId,
      'customer_id': customerId,
      'total_price': totalPrice,
      'status': status,
      'payment_status': paymentStatus,
      'paid_amount': paidAmount,
      'notes': notes,
      'estimated_completion_date': estimatedCompletionDate.toIso8601String(),
    };
  }
}
