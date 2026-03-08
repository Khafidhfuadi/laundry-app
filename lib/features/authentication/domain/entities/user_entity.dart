class UserEntity {
  final String id;
  final String email;
  final String role;
  final String name;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      email: json['email'] ?? '',
      role: json['role'] ?? 'staf',
      name: json['name'] ?? '',
    );
  }
}
