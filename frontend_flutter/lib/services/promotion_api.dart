import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/promotion.dart';
import 'staff_variant_api.dart';

class PromotionApi {
  PromotionApi({http.Client? client, required this.baseUrl})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<PromotionListResult> list({
    String? searchTerm,
    int page = 1,
    int pageSize = 10,
    bool includeDisable = true,
  }) async {
    final response = await _client.post(
      _uri('/api/Promotions/list'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'searchTerm': searchTerm?.trim().isEmpty == true ? null : searchTerm?.trim(),
        'includeDisable': includeDisable,
        'pagination': {'page': page, 'pageSize': pageSize},
      }),
    );
    _ensureSuccess(response);
    return PromotionListResult.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<void> create(PromotionInput input) async {
    final response = await _client.post(
      _uri('/api/Promotions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
  }

  Future<void> update(String id, PromotionInput input) async {
    final response = await _client.put(
      _uri('/api/Promotions/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
  }

  Future<void> delete(String id) async {
    final response = await _client.delete(_uri('/api/Promotions/$id'));
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
