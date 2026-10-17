import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_item.dart';

class CartApi {
  CartApi({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<CartItem>> getCartItems(int customerId) async {
    final response = await _client.get(_uri('/api/customer/cart/$customerId'));
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> getCartCount(int customerId) async {
    final response = await _client.get(_uri('/api/customer/cart/$customerId/count'));
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['count'] ?? 0) as int;
  }

  Future<void> updateQuantity(int cartItemId, int quantity, int customerId) async {
    final response = await _client.put(
      _uri('/api/customer/cart/$cartItemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cartItemId': cartItemId,
        'customerId': customerId,
        'quantity': quantity,
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> removeFromCart(int cartItemId, int customerId) async {
    final response = await _client.delete(
      _uri('/api/customer/cart/$cartItemId?customerId=$customerId'),
    );
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = 'API request failed (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          errorMessage = body['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
