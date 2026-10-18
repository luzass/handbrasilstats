class ProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String profileType;
  final String? cpfHash;
  final String? cpfLast4;
  final String role;
  final bool isActive;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.profileType,
    required this.cpfHash,
    required this.cpfLast4,
    required this.role,
    required this.isActive,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      profileType: (map['profile_type'] as String?) ?? 'visitor',
      cpfHash: map['cpf_hash'] as String?,
      cpfLast4: map['cpf_last4'] as String?,
      role: (map['role'] as String?) ?? 'viewer',
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}
