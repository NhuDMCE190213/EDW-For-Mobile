class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.phoneNumber,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final String? phoneNumber;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final rawId =
        json['id'] ??
        json['userId'] ??
        json['staffId'] ??
        json['customerId'] ??
        json['Id'] ??
        json['UserId'];
    final rawActive =
        json['isActive'] ??
        json['IsActive'] ??
        json['active'] ??
        json['Active'] ??
        true;
    return AdminUser(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      fullName:
          '${json['fullName'] ?? json['FullName'] ?? json['name'] ?? json['Name'] ?? ''}',
      email: '${json['email'] ?? json['Email'] ?? ''}',
      role: '${json['role'] ?? json['Role'] ?? ''}',
      isActive: rawActive is bool
          ? rawActive
          : rawActive.toString().toLowerCase() == 'true',
      phoneNumber: (json['phoneNumber'] ?? json['PhoneNumber'])?.toString(),
    );
  }
}

class CreateAdminUserInput {
  const CreateAdminUserInput({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
  });

  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'password': password,
    if (phoneNumber != null && phoneNumber!.isNotEmpty)
      'phoneNumber': phoneNumber,
  };
}
