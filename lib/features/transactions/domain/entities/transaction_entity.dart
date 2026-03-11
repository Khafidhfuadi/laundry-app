import '../../../customers/domain/entities/customer_entity.dart';
import '../../../outlet/domain/entities/outlet_entity.dart';
import '../../../services/domain/entities/service_entity.dart';
import '../../../perfumes/domain/entities/perfume_entity.dart';

class TransactionItemEntity {
  final String id;
  final String transactionId;
  final String serviceVariantId;
  final double quantity;
  final double subtotal;
  final ServiceVariantEntity? serviceVariant; // Join data

  const TransactionItemEntity({
    required this.id,
    required this.transactionId,
    required this.serviceVariantId,
    required this.quantity,
    required this.subtotal,
    this.serviceVariant,
  });

  factory TransactionItemEntity.fromJson(Map<String, dynamic> json) {
    return TransactionItemEntity(
      id: json['id'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      serviceVariantId: json['service_variant_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      serviceVariant: json['service_variants'] != null
          ? ServiceVariantEntity.fromJson(json['service_variants'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (transactionId.isNotEmpty) 'transaction_id': transactionId,
      'service_variant_id': serviceVariantId,
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
  final String? perfumeId;
  final DateTime estimatedCompletionDate;
  final DateTime createdAt;

  // Relations
  final CustomerEntity? customer;
  final OutletEntity? outlet;
  final PerfumeEntity? perfume;
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
    this.perfumeId,
    required this.estimatedCompletionDate,
    required this.createdAt,
    this.customer,
    this.outlet,
    this.perfume,
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
      perfumeId: json['perfume_id'] as String?,
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
      perfume: json['perfumes'] != null
          ? PerfumeEntity.fromJson(json['perfumes'])
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
      if (perfumeId != null) 'perfume_id': perfumeId,
      'estimated_completion_date': estimatedCompletionDate.toIso8601String(),
    };
  }
}
