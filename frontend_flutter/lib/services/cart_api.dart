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

  Future<void> removeFromCart(int cartItemId, int customerId) async {
    final response = await _client.delete(
        _uri('/api/customer/cart/$cartItemId?customerId=$customerId'));
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API request failed (${response.statusCode})');
    }
  }
}
