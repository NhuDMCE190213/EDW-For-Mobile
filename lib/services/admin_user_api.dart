import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin_user.dart';
import 'api_exception.dart';

class AdminUserApi {
  AdminUserApi({http.Client? client, required this.baseUrl})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<List<AdminUser>> getStaff() => _get('/api/admin/staff');
  Future<List<AdminUser>> getCustomers() => _get('/api/admin/customers');

  Future<void> createStaff(CreateAdminUserInput input) async {
    final response = await _client.post(
      _uri('/api/admin/staff'),
      headers: _headers,
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
  }

  Future<void> createCustomer(CreateAdminUserInput input) async {
    final response = await _client.post(
      _uri('/api/admin/customers'),
      headers: _headers,
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
  }

  Future<void> setStaffActive(int id, bool isActive) =>
      _setActive('/api/admin/staff/$id/status', id, isActive);

  Future<void> setCustomerActive(int id, bool isActive) =>
      _setActive('/api/admin/customers/$id/status', id, isActive);

  Future<List<AdminUser>> _get(String path) async {
    final response = await _client.get(_uri(path));
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    final values = decoded is Map
        ? (decoded['items'] ?? decoded['data'] ?? decoded['Items'] ?? decoded['Data'] ?? [])
        : decoded;
    return (values as List)
        .map((item) => AdminUser.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> _setActive(String path, int id, bool isActive) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode({'id': id, 'isActive': isActive}),
    );
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = response.body.trim();
      if (detail.length > 200) detail = detail.substring(0, 200);
      throw ApiException(
        'API request failed (${response.statusCode})${detail.isEmpty ? '' : ': $detail'}',
      );
    }
  }
}
