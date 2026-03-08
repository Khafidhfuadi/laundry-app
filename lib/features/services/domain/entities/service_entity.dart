class ServiceEntity {
  final String id;
  final String categoryName;
  final String itemName;
  final String variant;
  final String unitType;
  final double price;
  final String serviceType;
  final int estimatedHours;

  const ServiceEntity({
    required this.id,
    required this.categoryName,
    required this.itemName,
    required this.variant,
    required this.unitType,
    required this.price,
    required this.serviceType,
    required this.estimatedHours,
  });

  // Konstruktor untuk membuat dari Supabase Join Query
  // Format JSON yang diharapkan:
  // {
  //   "id": "...",
  //   "variant": "...",
  //   "unit_type": "Kg",
  //   "price": 6000,
  //   "service_type": "Reguler",
  //   "estimated_hours": 48,
  //   "service_items": {
  //      "name": "Pakaian",
  //      "service_categories": { "name": "Laundry" }
  //   }
  // }
  factory ServiceEntity.fromJson(Map<String, dynamic> json) {
    final itemInfo = json['service_items'] ?? {};
    final categoryInfo = itemInfo['service_categories'] ?? {};

    return ServiceEntity(
      id: json['id'] as String,
      categoryName: categoryInfo['name'] as String? ?? 'Kategori Umum',
      itemName: itemInfo['name'] as String? ?? 'Item Umum',
      variant: json['variant'] as String? ?? '',
      unitType: json['unit_type'] as String? ?? 'Pcs',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      serviceType: json['service_type'] as String? ?? 'Reguler',
      estimatedHours: json['estimated_hours'] as int? ?? 24,
    );
  }

  // Helper untuk menampilkan nama lengkap layanan
  String get fullName {
    if (variant.isNotEmpty) return '$itemName $variant';
    return itemName;
  }
}
