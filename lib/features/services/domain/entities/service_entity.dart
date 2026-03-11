class ServiceEntity {
  final String id;
  final String serviceItemId;
  final String categoryName;
  final String itemName;
  final String variant;
  final String unitType;
  final double price;
  final String serviceType;
  final int estimatedHours;

  const ServiceEntity({
    required this.id,
    required this.serviceItemId,
    required this.categoryName,
    required this.itemName,
    required this.variant,
    required this.unitType,
    required this.price,
    required this.serviceType,
    required this.estimatedHours,
  });

  factory ServiceEntity.fromJson(Map<String, dynamic> json) {
    final itemInfo = json['service_items'] ?? {};
    final categoryInfo = itemInfo['service_categories'] ?? {};

    return ServiceEntity(
      id: json['id'] as String,
      serviceItemId: json['service_item_id'] as String? ?? '',
      categoryName: categoryInfo['name'] as String? ?? 'Kategori Umum',
      itemName: itemInfo['name'] as String? ?? 'Item Umum',
      variant: json['variant'] as String? ?? '',
      unitType: json['unit_type'] as String? ?? 'Pcs',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      serviceType: json['service_type'] as String? ?? 'Reguler',
      estimatedHours: json['estimated_hours'] as int? ?? 24,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serviceItemId.isNotEmpty) 'service_item_id': serviceItemId,
      'variant': variant,
      'unit_type': unitType,
      'price': price,
      'service_type': serviceType,
      'estimated_hours': estimatedHours,
    };
  }

  ServiceEntity copyWith({
    String? id,
    String? serviceItemId,
    String? categoryName,
    String? itemName,
    String? variant,
    String? unitType,
    double? price,
    String? serviceType,
    int? estimatedHours,
  }) {
    return ServiceEntity(
      id: id ?? this.id,
      serviceItemId: serviceItemId ?? this.serviceItemId,
      categoryName: categoryName ?? this.categoryName,
      itemName: itemName ?? this.itemName,
      variant: variant ?? this.variant,
      unitType: unitType ?? this.unitType,
      price: price ?? this.price,
      serviceType: serviceType ?? this.serviceType,
      estimatedHours: estimatedHours ?? this.estimatedHours,
    );
  }

  // Helper untuk menampilkan nama lengkap layanan
  String get fullName {
    if (variant.isNotEmpty) return '$itemName $variant';
    return itemName;
  }
}
