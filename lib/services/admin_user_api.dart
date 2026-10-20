import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin_user.dart';
import 'api_exception.dart';

class AdminUserApi {
  AdminUserApi({http.Client? client, required this.baseUrl, this.authToken})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  String? authToken;

  void setAuthToken(String? token) => authToken = token;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null && authToken!.isNotEmpty)
      'Authorization': 'Bearer $authToken',
  };

  Future<List<AdminUser>> getStaff() => _get('/api/admin/staffs/list');

  Future<List<AdminUser>> getCustomers() => _get('/api/admin/customers/list');

  Future<void> createStaff(CreateAdminUserInput input) async {
    final response = await _client.post(
      _uri('/api/admin/staffs'),
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
      _toggleActive('/api/admin/staffs/$id/toggle-status');

  Future<void> setCustomerActive(int id, bool isActive) =>
      _toggleActive('/api/admin/customers/$id/toggle-status');

  Future<List<AdminUser>> _get(String path) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode({
        'searchTerm': null,
        'includeDelete': false,
        'includeDisable': true,
        'pagination': {'page': 1, 'pageSize': 100},
      }),
    );
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    final values = _extractItems(decoded);
    return (values as List)
        .map(
          (item) => AdminUser.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> _toggleActive(String path) async {
    final response = await _client.put(_uri(path), headers: _headers);
    _ensureSuccess(response);
  }

  Object _extractItems(Object decoded) {
    if (decoded is List) return decoded;
    if (decoded is! Map) return const <Object>[];
    return decoded['items'] ??
        decoded['Items'] ??
        (decoded['pagination'] is Map
            ? (decoded['pagination'] as Map)['items'] ??
                  (decoded['pagination'] as Map)['Items']
            : null) ??
        (decoded['Pagination'] is Map
            ? (decoded['Pagination'] as Map)['items'] ??
                  (decoded['Pagination'] as Map)['Items']
            : null) ??
        decoded['data'] ??
        decoded['Data'] ??
        const <Object>[];
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = response.body.trim();
      if (detail.length > 200) detail = detail.substring(0, 200);
      throw ApiException(
        'API request failed (${response.statusCode})'
        '${detail.isEmpty ? '' : ': $detail'}',
      );
    }
  }
}
