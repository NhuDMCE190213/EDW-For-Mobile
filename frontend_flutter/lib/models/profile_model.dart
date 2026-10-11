class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.points,
    this.isActive,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final int? points;
  final bool? isActive;
  final DateTime? createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final idRaw = json['customerId'] ?? json['staffId'] ?? json['id'] ?? 0;
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];

    return UserProfile(
      id: idRaw is num ? idRaw.toInt() : int.tryParse(idRaw.toString()) ?? 0,
      fullName: (json['fullName'] ?? json['FullName'] ?? '') as String,
      email: (json['email'] ?? json['Email'] ?? '') as String,
      phoneNumber: json['phoneNumber'] as String?,
      points: (json['points'] as num?)?.toInt(),
      isActive: json['isActive'] as bool?,
      createdAt: createdAtRaw != null ? DateTime.tryParse(createdAtRaw.toString()) : null,
    );
  }
}
