import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_model.dart';
import 'staff_variant_api.dart';

class AuthApi {
  AuthApi({
    http.Client? client,
    required this.baseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// UC-01.1: Customer Login
  Future<LoginResponse> customerLogin(LoginInput input) async {
    final response = await _client.post(
      _uri('/api/auth/customer/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
    return LoginResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// UC-01.2: Staff Login
  Future<LoginResponse> staffLogin(LoginInput input) async {
    final response = await _client.post(
      _uri('/api/auth/staff/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
    return LoginResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// UC-03: Register for Customer
  Future<void> register(CustomerRegisterInput input) async {
    final response = await _client.post(
      _uri('/api/auth/customer/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
  }

  /// UC-02: Logout (Customer, Staff, Admin)
  Future<void> logout(String token) async {
    final response = await _client.post(
      _uri('/api/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _ensureSuccess(response);
  }

  /// UC-04: Verify Customer Email for Password Reset
  Future<void> verifyCustomerEmail(String email) async {
    final response = await _client.post(
      _uri('/api/auth/customer/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    _ensureSuccess(response);
  }

  /// UC-04: Reset Customer Password
  Future<void> resetCustomerPassword(String email, String newPassword) async {
    final response = await _client.post(
      _uri('/api/auth/customer/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': newPassword}),
    );
    _ensureSuccess(response);
  }

  /// UC-04: Verify Staff Email for Password Reset
  Future<void> verifyStaffEmail(String email) async {
    final response = await _client.post(
      _uri('/api/auth/staff/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    _ensureSuccess(response);
  }

  /// UC-04: Reset Staff Password
  Future<void> resetStaffPassword(String email, String newPassword) async {
    final response = await _client.post(
      _uri('/api/auth/staff/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': newPassword}),
    );
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'API request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('message') && decoded['message'] != null) {
            message = decoded['message'].toString();
          } else if (decoded.containsKey('errors') && decoded['errors'] is Map) {
            final errors = decoded['errors'] as Map<String, dynamic>;
            final errorList = <String>[];
            for (final entry in errors.entries) {
              if (entry.value is List) {
                errorList.addAll((entry.value as List).map((e) => e.toString()));
              } else if (entry.value != null) {
                errorList.add(entry.value.toString());
              }
            }
            if (errorList.isNotEmpty) {
              message = errorList.join('\n');
            }
          } else if (decoded.containsKey('title') && decoded['title'] != null) {
            message = decoded['title'].toString();
          }
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          message = response.body.length > 200
              ? response.body.substring(0, 200)
              : response.body;
        }
      }
      throw ApiException(message);
    }
  }
}
