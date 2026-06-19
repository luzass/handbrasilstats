class ProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String role;
  final bool isActive;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      role: (map['role'] as String?) ?? 'viewer',
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}