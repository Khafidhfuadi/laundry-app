class PerfumeEntity {
  final String id;
  final String name;

  const PerfumeEntity({
    required this.id,
    required this.name,
  });

  factory PerfumeEntity.fromJson(Map<String, dynamic> json) {
    return PerfumeEntity(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
    };
  }

  PerfumeEntity copyWith({
    String? id,
    String? name,
  }) {
    return PerfumeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
