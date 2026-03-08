class OutletEntity {
  final String id;
  final String name;
  final String address;
  final String phone;
  final bool isActive;
  final DateTime createdAt;

  const OutletEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.isActive,
    required this.createdAt,
  });

  factory OutletEntity.fromJson(Map<String, dynamic> json) {
    return OutletEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'is_active': isActive,
    };
  }
}
