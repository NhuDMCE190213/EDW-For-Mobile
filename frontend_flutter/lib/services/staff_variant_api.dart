import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_variant.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StaffVariantApi {
  StaffVariantApi({
    http.Client? client,
    required this.baseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<ProductSummary>> getProducts() async {
    final response = await _client.get(_uri('/api/staff/products'));
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List)
        .map((item) => ProductSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductVariant>> getVariants({int? productId}) async {
    final path = productId == null
        ? '/api/staff/product-variants'
        : '/api/staff/product-variants/by-product/$productId';
    final response = await _client.get(_uri(path));
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List)
        .map((item) => ProductVariant.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(ProductVariantInput input) async {
    final response = await _client.post(
      _uri('/api/staff/product-variants'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
  }

  Future<void> update(ProductVariantInput input) async {
    final response = await _client.put(
      _uri('/api/staff/product-variants/${input.productVariantId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson(includeId: true)),
    );
    _ensureSuccess(response);
  }

  Future<void> delete(String id) async {
    final response = await _client.delete(_uri('/api/staff/product-variants/$id'));
    _ensureSuccess(response);
  }

  Future<void> stockIn(String id, int amount) async {
    final response = await _client.post(
      _uri('/api/staff/product-variants/$id/stock-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(amount),
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
