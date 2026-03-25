import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.read(key: 'token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(String path, {bool auth = true}) async {
    return _client.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _client.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
  }

  Future<Map<String, dynamic>> getJson(String path, {bool auth = true}) async {
    final response = await get(path, auth: auth);
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final response = await post(path, body: body, auth: auth);
    return _decode(response);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'token');
  }

  /// Formate les erreurs Django REST (detail, non_field_errors, champs).
  static String _formatApiError(Map<String, dynamic> data, int statusCode) {
    final detail = data['detail'];
    if (detail is List && detail.isNotEmpty) {
      return detail.map((e) => e.toString()).join(' ');
    }
    if (detail is Map && detail.isNotEmpty) {
      return detail.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(' ');
    }
    if (detail != null && detail is! Map) {
      return detail.toString();
    }

    final nonField = data['non_field_errors'];
    if (nonField is List && nonField.isNotEmpty) {
      return nonField.map((e) => e.toString()).join(' ');
    }

    final parts = <String>[];
    for (final e in data.entries) {
      if (e.key == 'detail') continue;
      final v = e.value;
      if (v is List) {
        parts.add('${e.key}: ${v.map((x) => x.toString()).join(', ')}');
      } else if (v is Map) {
        parts.add('${e.key}: $v');
      } else if (v != null) {
        parts.add('${e.key}: $v');
      }
    }
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    if (data.isEmpty) {
      return 'Erreur serveur ($statusCode). Vérifiez le corps de la requête (JSON téléphone + mot de passe).';
    }
    return (data['message'] ?? 'Erreur API ($statusCode)').toString();
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Object?;
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _formatApiError(data, response.statusCode);
      throw ApiException(message: message, statusCode: response.statusCode);
    }
    return data;
  }
}

class ApiException implements Exception {
  ApiException({required this.message, required this.statusCode});
  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
