//Tiêu Gia Huy
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/customer_shopping.dart';
import 'api_exception.dart';

class CustomerShoppingApi {
  CustomerShoppingApi({
    required this.baseUrl,
    required this.token,
    http.Client? client,
  }) : _client = client ?? http.Client();
  final String baseUrl, token;
  final http.Client _client;
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  Uri _uri(String path) => Uri.parse(
    '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/customer/shopping/$path',
  );

  Future<List<ShopProduct>> getProducts() async {
    final response = await _client
        .get(_uri('products'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    _check(response);
    return (jsonDecode(response.body) as List)
        .map((p) => ShopProduct.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShopCartItem>> getCart() async {
    final response = await _client
        .get(_uri('cart'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    _check(response);
    return (jsonDecode(response.body) as List)
        .map((p) => ShopCartItem.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateQuantity(int id, int quantity) async {
    if (quantity < 1) throw const ApiException('Quantity must be at least 1.');
    _check(
      await _client
          .put(
            _uri('cart/$id/quantity'),
            headers: _headers,
            body: jsonEncode({'quantity': quantity}),
          )
          .timeout(const Duration(seconds: 20)),
    );
  }

  Future<void> removeItem(int id) async {
    _check(
      await _client
          .delete(_uri('cart/$id'), headers: _headers)
          .timeout(const Duration(seconds: 20)),
    );
  }

  String? imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final uri = Uri.tryParse(baseUrl)?.resolve(path.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https')
        ? uri.toString()
        : null;
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401) {
      throw const ApiException('Session expired. Please sign in again.');
    }
    if (response.statusCode == 403) {
      throw const ApiException('You cannot access this cart.');
    }
    String message =
        'Request failed (${response.statusCode}). Please try again.';
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json['message'] is String) {
        message = json['message'] as String;
      }
    } on FormatException {
      /* Do not expose HTML or server stack traces. */
    }
    throw ApiException(message);
  }

  void close() => _client.close();
}
