//Tiêu Gia Huy
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/customer_shopping.dart';
import 'api_exception.dart';

class CustomerShoppingApi {
  CustomerShoppingApi({
    required this.baseUrl,
    required this.token,
    this.customerId,
    http.Client? client,
  }) : _client = client ?? http.Client();
  final String baseUrl, token;
  final int? customerId;
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
        .get(
          Uri.parse(
            '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/customer/products',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 20));
    _check(response);
    return (jsonDecode(response.body) as List)
        .map((p) => ShopProduct.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<ShopProduct> getProduct(int productId) async {
    final response = await _client
        .get(
          Uri.parse(
            '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/customer/products/$productId',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 20));
    _check(response);
    return ShopProduct.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> addToCart({
    required int customerId,
    required String productVariantId,
    int quantity = 1,
  }) async {
    if (quantity < 1) {
      throw const ApiException('Quantity must be at least 1.');
    }
    final response = await _client
        .post(
          Uri.parse(
            '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/customer/cart',
          ),
          headers: _headers,
          body: jsonEncode({
            'customerId': customerId,
            'productVariantId': productVariantId,
            'quantity': quantity,
          }),
        )
        .timeout(const Duration(seconds: 20));
    _check(response);
  }

  Future<List<ShopCartItem>> getCart() async {
    final response = await _client
        .get(
          customerId == null
              ? _uri('cart')
              : Uri.parse(
                  '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/customer/cart/$customerId',
                ),
          headers: _headers,
        )
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
            customerId == null
                ? _uri('cart/$id/quantity')
                : Uri.parse(
                    '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/customer/cart/$id',
                  ),
            headers: _headers,
            body: jsonEncode(
              customerId == null
                  ? {'quantity': quantity}
                  : {
                      'cartItemId': id,
                      'customerId': customerId,
                      'quantity': quantity,
                    },
            ),
          )
          .timeout(const Duration(seconds: 20)),
    );
  }

  Future<void> removeItem(int id) async {
    _check(
      await _client
          .delete(
            customerId == null
                ? _uri('cart/$id')
                : Uri.parse(
                    '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/customer/cart/$id?customerId=$customerId',
                  ),
            headers: _headers,
          )
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
