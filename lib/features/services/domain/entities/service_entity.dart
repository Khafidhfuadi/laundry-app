class ServiceVariantEntity {
  final String id;
  final String serviceId;
  final String variantName;
  final String unitType;
  final double price;
  final String serviceType;
  final int estimatedHours;
  final String notes;
  final int sortOrder;
  final ServiceEntity? service; // Parent reference for joins

  const ServiceVariantEntity({
    required this.id,
    required this.serviceId,
    required this.variantName,
    required this.unitType,
    required this.price,
    required this.serviceType,
    required this.estimatedHours,
    required this.notes,
    this.sortOrder = 0,
    this.service,
  });

  factory ServiceVariantEntity.fromJson(Map<String, dynamic> json) {
    return ServiceVariantEntity(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      variantName: json['variant'] as String? ?? '',
      unitType: json['unit_type'] as String? ?? 'Kg',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      serviceType: json['service_type'] as String? ?? 'Reguler',
      estimatedHours: json['estimated_hours'] as int? ?? 24,
      notes: json['notes'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      service: json['services'] != null
          ? ServiceEntity.fromJson(json['services'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (serviceId.isNotEmpty) 'service_id': serviceId,
      'variant': variantName,
      'unit_type': unitType,
      'price': price,
      'service_type': serviceType,
      'estimated_hours': estimatedHours,
      'notes': notes,
      'sort_order': sortOrder,
    };
  }

  ServiceVariantEntity copyWith({
    String? id,
    String? serviceId,
    String? variantName,
    String? unitType,
    double? price,
    String? serviceType,
    int? estimatedHours,
    String? notes,
    int? sortOrder,
    ServiceEntity? service,
  }) {
    return ServiceVariantEntity(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      variantName: variantName ?? this.variantName,
      unitType: unitType ?? this.unitType,
      price: price ?? this.price,
      serviceType: serviceType ?? this.serviceType,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      service: service ?? this.service,
    );
  }
}

class ServiceEntity {
  final String id;
  final String name; // Nama Produk
  final String categoryId;
  final String categoryName;
  final String processType;
  final int sortOrder;
  final List<ServiceVariantEntity> variants;

  const ServiceEntity({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.processType,
    this.sortOrder = 0,
    this.variants = const [],
  });

  factory ServiceEntity.fromJson(Map<String, dynamic> json) {
    final cat = json['service_categories'] ?? {};
    return ServiceEntity(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      categoryName: cat['name'] as String? ?? 'Layanan Umum',
      processType: json['process_type'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      variants: json['service_variants'] != null
          ? (json['service_variants'] as List)
                .map((e) => ServiceVariantEntity.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      if (categoryId.isNotEmpty) 'category_id': categoryId,
      'process_type': processType,
      'sort_order': sortOrder,
      // variants biasanya tidak dimasukkan saat toJson entity parent kecuali bulk upsert manual
    };
  }

  ServiceEntity copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    String? processType,
    int? sortOrder,
    List<ServiceVariantEntity>? variants,
  }) {
    return ServiceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      processType: processType ?? this.processType,
      sortOrder: sortOrder ?? this.sortOrder,
      variants: variants ?? this.variants,
    );
  }
}
