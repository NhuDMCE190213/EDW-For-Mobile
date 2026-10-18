import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/review.dart';
import 'api_exception.dart';

class ReviewApi {
  ReviewApi({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final baseUri = Uri.parse('$baseUrl$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return baseUri;
    }
    final cleanParams = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        cleanParams[key] = value.toString();
      }
    });
    return baseUri.replace(queryParameters: cleanParams);
  }

  // ==========================================
  // UC-06.1, UC-06.2, UC-06.3: STAFF & ADMIN
  // ==========================================

  /// UC-06.1: View Reviews for Staff & Admin
  Future<List<ReviewItem>> getStaffReviews({
    String? searchTerm,
    int? productId,
    int? rating,
    bool? onlyFlagged,
  }) async {
    final uri = _uri('/api/staff/reviews', {
      if (searchTerm != null && searchTerm.trim().isNotEmpty)
        'searchTerm': searchTerm.trim(),
      if (productId != null && productId > 0) 'productId': productId,
      if (rating != null && rating > 0) 'rating': rating,
      if (onlyFlagged == true) 'onlyFlagged': true,
    });

    final response = await _client.get(uri);
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body) as List;
    return decoded
        .map((item) => ReviewItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReviewItem>> getProductReviews(int productId) async {
    final response = await _client.get(
      _uri('/api/staff/reviews', {'productId': productId}),
    );
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body) as List;
    return decoded
        .map((item) => ReviewItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// UC-06.2: Flag Review
  Future<void> flagReview(int id, {String? reason, String? flaggedBy}) async {
    final response = await _client.post(
      _uri('/api/staff/reviews/$id/flag'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        if (flaggedBy != null && flaggedBy.trim().isNotEmpty)
          'flaggedBy': flaggedBy.trim(),
      }),
    );
    _ensureSuccess(response);
  }

  /// UC-06.2: Unflag Review
  Future<void> unflagReview(int id) async {
    final response = await _client.post(
      _uri('/api/staff/reviews/$id/unflag'),
      headers: {'Content-Type': 'application/json'},
    );
    _ensureSuccess(response);
  }

  /// UC-06.3: Moderate Product Review (Admin Only - Rule FR-01)
  Future<void> moderateReview(
    int id, {
    required bool isHidden,
    String? note,
  }) async {
    final response = await _client.put(
      _uri('/api/admin/reviews/$id/moderate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'isHidden': isHidden,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      }),
    );
    _ensureSuccess(response);
  }

  // ==========================================
  // UC-07.1, UC-07.2, UC-07.3: CUSTOMER
  // ==========================================

  /// UC-07.1: View My Reviews
  Future<List<ReviewItem>> getMyReviews(int customerId) async {
    final response = await _client.get(
      _uri('/api/customer/reviews', {'customerId': customerId}),
    );
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body) as List;
    return decoded
        .map((item) => ReviewItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get Review by ID
  Future<ReviewItem> getReviewById(int id) async {
    final response = await _client.get(_uri('/api/customer/reviews/$id'));
    _ensureSuccess(response);
    return ReviewItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// UC-07.2: Create Review
  Future<void> createReview(CreateReviewInput input) async {
    final response = await _client.post(
      _uri('/api/customer/reviews'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
  }

  /// UC-07.3: Update Review
  Future<void> updateReview(int id, UpdateReviewInput input) async {
    final response = await _client.put(
      _uri('/api/customer/reviews/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input.toJson()),
    );
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'API request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('message') && decoded['message'] != null) {
            message = decoded['message'].toString();
          } else if (decoded.containsKey('errors') &&
              decoded['errors'] is Map) {
            final errors = decoded['errors'] as Map<String, dynamic>;
            final errorList = <String>[];
            for (final entry in errors.entries) {
              if (entry.value is List) {
                errorList.addAll(
                  (entry.value as List).map((e) => e.toString()),
                );
              } else if (entry.value != null) {
                errorList.add(entry.value.toString());
              }
            }
            if (errorList.isNotEmpty) {
              message = errorList.join('\n');
            }
          } else if (decoded.containsKey('title') && decoded['title'] != null) {
            message = decoded['title'].toString();
          }
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          message = response.body.length > 200
              ? response.body.substring(0, 200)
              : response.body;
        }
      }
      throw ApiException(message);
    }
  }
}
