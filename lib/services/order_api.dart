import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';

class OrderApi {
  OrderApi({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  // ===========================================================================
  // CUSTOMER ORDERS
  // ===========================================================================



  /// UC-27: My Cart - Transfer to Order (Customer)
  /// UC-41: My Order - Checkout (Customer)
  /// Converts selected cart items into an order and processes checkout.
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


  // ===========================================================================
  // STAFF / ADMIN ORDERS
  // ===========================================================================


  /// UC-35: Order Management - View Order Dashboard (Admin)
  /// Fetches statistical overview KPIs (totals, revenue, statuses).
  Future<OrderDashboard> getOrderDashboard() async {
    final response = await _client.get(_uri('/api/staff/orders/dashboard'));
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return OrderDashboard.fromJson(json);
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
