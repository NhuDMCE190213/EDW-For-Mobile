import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin_catalog.dart';
import 'api_exception.dart';

class AdminCatalogApi {
  AdminCatalogApi({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<AdminCategory>> getCategories() async {
    final response = await _client.get(_uri('/api/admin/categories'));
    _ensureSuccess(response);
    return _decodeList(response.body)
        .map((item) => AdminCategory.fromJson(item))
        .toList();
  }

  Future<AdminCategory> createCategory(CategoryInput input) async {
    final response = await _client.post(
      _uri('/api/admin/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
    return AdminCategory.fromJson(_decodeObject(response.body));
  }

  Future<void> updateCategory(CategoryInput input) async {
    final id = input.id;
    if (id == null) throw const ApiException('Category id is required.');
    final response = await _client.put(
      _uri('/api/admin/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson(includeId: true)),
    );
    _ensureSuccess(response);
  }

  Future<void> deleteCategory(int id) async {
    final response = await _client.delete(_uri('/api/admin/categories/$id'));
    _ensureSuccess(response);
  }

  Future<List<AdminProduct>> getProducts() async {
    final response = await _client.get(_uri('/api/admin/products'));
    _ensureSuccess(response);
    return _decodeList(response.body)
        .map((item) => AdminProduct.fromJson(item))
        .toList();
  }

  Future<AdminProduct> createProduct(ProductInput input) async {
    final response = await _client.post(
      _uri('/api/admin/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
    return AdminProduct.fromJson(_decodeObject(response.body));
  }

  Future<void> updateProduct(ProductInput input) async {
    final id = input.productId;
    if (id == null) throw const ApiException('Product id is required.');
    final response = await _client.put(
      _uri('/api/admin/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson(includeId: true)),
    );
    _ensureSuccess(response);
  }

  Future<void> deleteProduct(int id) async {
    final response = await _client.delete(_uri('/api/admin/products/$id'));
    _ensureSuccess(response);
  }

  List<Map<String, dynamic>> _decodeList(String body) {
    final decoded = jsonDecode(body) as List;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Map<String, dynamic> _decodeObject(String body) {
    return Map<String, dynamic>.from(jsonDecode(body) as Map);
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
