import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/profile_model.dart';
import 'staff_variant_api.dart';

class ProfileApi {
  ProfileApi({
    http.Client? client,
    required this.baseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// UC-05.1: View Profile (All: Customer, Staff, Admin)
  Future<UserProfile> getProfile(String token) async {
    final response = await _client.get(
      _uri('/api/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _ensureSuccess(response);
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// UC-05.2: Edit Profile (All)
  Future<void> updateProfile(
    String token, {
    required String fullName,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName,
      'phoneNumber': phoneNumber ?? '',
    };

    final response = await _client.put(
      _uri('/api/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
  }

  /// UC-05.3: Change Password (All)
  Future<void> changePassword(
    String token, {
    required String newPassword,
    required String confirmPassword,
  }) async {
    final body = <String, dynamic>{
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };

    final response = await _client.put(
      _uri('/api/profile/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Thao tác thất bại (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('message') && decoded['message'] != null) {
            message = decoded['message'].toString();
          } else if (decoded.containsKey('errors') && decoded['errors'] is Map) {
            final errors = decoded['errors'] as Map<String, dynamic>;
            final errorList = <String>[];
            for (final entry in errors.entries) {
              if (entry.value is List) {
                errorList.addAll((entry.value as List).map((e) => e.toString()));
              } else if (entry.value != null) {
                errorList.add(entry.value.toString());
              }
            }
            if (errorList.isNotEmpty) {
              message = errorList.join('\n');
            }
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
