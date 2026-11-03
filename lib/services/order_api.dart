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

  /// UC-38: My Order - View My Orders (Customer)
  /// Fetches the list of orders belonging to the specified customer.
  Future<List<Order>> getMyOrders(int customerId) async {
    final response = await _client.get(
      _uri('/api/customer/orders/$customerId'),
    );
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// UC-40: My Order - Transfer Product to Cart (Customer)
  /// Transfers items from an existing order back into the shopping cart.
  Future<void> transferToCart(String orderId, int customerId) async {
    final response = await _client.post(
      _uri('/api/customer/orders/$orderId/transfer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(customerId),
    );
    _ensureSuccess(response);
  }

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

  /// UC-39: My Order - Remove Product / Cancel Order (Customer)
  /// Cancels an existing order (removing/releasing ordered products).
  Future<void> cancelOrder(String orderId) async {
    final response = await _client.post(
      _uri('/api/customer/orders/$orderId/cancel'),
    );
    _ensureSuccess(response);
  }

  // ===========================================================================
  // STAFF / ADMIN ORDERS
  // ===========================================================================

  /// UC-36: Order Management - View Orders (Admin/Staff)
  /// Fetches all customer orders across the platform for management.
  Future<List<Order>> getAllOrders() async {
    final response = await _client.get(_uri('/api/staff/orders'));
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// UC-35: Order Management - View Order Dashboard (Admin)
  /// Fetches statistical overview KPIs (totals, revenue, statuses).
  Future<OrderDashboard> getOrderDashboard() async {
    final response = await _client.get(_uri('/api/staff/orders/dashboard'));
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return OrderDashboard.fromJson(json);
  }

  /// UC-37: Order Management - Change Order Status (Admin/Staff)
  /// Updates the lifecycle status of an order (e.g. Processing, Shipped, Completed, Cancelled).
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
