class LoginInput {
  const LoginInput({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  final String email;
  final String password;
  final bool rememberMe;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
      };
}

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String token;
  final DateTime expiresAt;
  final int userId;
  final String fullName;
  final String email;
  final String role;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final expiresAtRaw = json['expiresAt'] ?? json['ExpiresAt'];
    final userIdRaw = json['userId'] ?? json['UserId'];
    final roleRaw = json['role'] ?? json['Role'];

    return LoginResponse(
      token: (json['token'] ?? json['Token'] ?? '') as String,
      expiresAt: DateTime.tryParse(expiresAtRaw?.toString() ?? '') ?? DateTime.now(),
      userId: userIdRaw is num ? userIdRaw.toInt() : int.tryParse(userIdRaw?.toString() ?? '0') ?? 0,
      fullName: (json['fullName'] ?? json['FullName'] ?? '') as String,
      email: (json['email'] ?? json['Email'] ?? '') as String,
      role: roleRaw?.toString() ?? '',
    );
  }

  String get roleDisplayName {
    switch (role) {
      case '0':
      case 'Admin':
        return 'Quản trị viên';
      case '1':
      case 'Staff':
        return 'Nhân viên';
      case '2':
      case 'Customer':
        return 'Khách hàng';
      default:
        return role.isNotEmpty ? role : 'Khách hàng';
    }
  }
}

class CustomerRegisterInput {
  const CustomerRegisterInput({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      };
}
