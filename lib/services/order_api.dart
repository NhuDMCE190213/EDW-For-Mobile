import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';

class OrderApi {
  OrderApi({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  // Customer Orders
  Future<List<Order>> getMyOrders(int customerId) async {
    final response = await _client.get(
      _uri('/api/customer/orders/$customerId'),
    );
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> transferToCart(String orderId, int customerId) async {
    final response = await _client.post(
      _uri('/api/customer/orders/$orderId/transfer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(customerId),
    );
    _ensureSuccess(response);
  }

  Future<CheckoutResult> checkoutCart(int customerId, List<int> selectedCartItemIds) async {
    final response = await _client.post(
      _uri('/api/customer/orders/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
        'selectedCartItemIds': selectedCartItemIds,
      }),
    );
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CheckoutResult.fromJson(json);
  }

  Future<void> cancelOrder(String orderId) async {
    final response = await _client.post(
      _uri('/api/customer/orders/$orderId/cancel'),
    );
    _ensureSuccess(response);
  }

  // Staff / Admin Orders
  Future<List<Order>> getAllOrders() async {
    final response = await _client.get(_uri('/api/staff/orders'));
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderDashboard> getOrderDashboard() async {
    final response = await _client.get(_uri('/api/staff/orders/dashboard'));
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return OrderDashboard.fromJson(json);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final response = await _client.put(
      _uri('/api/staff/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(status),
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
