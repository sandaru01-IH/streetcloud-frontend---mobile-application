import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.status = 0});
  final String message;
  final int status;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient();

  static const _baseKey = 'streetcloud.apiBase';
  static const _accessKey = 'streetcloud.access';
  static const _refreshKey = 'streetcloud.refresh';

  final _secure = const FlutterSecureStorage();
  String apiBase = 'http://127.0.0.1:8000';
  String? accessToken;
  String? refreshToken;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_baseKey);
    if (stored != null && stored.isNotEmpty) apiBase = stored.replaceAll(RegExp(r'/+$'), '');
    accessToken = await _secure.read(key: _accessKey);
    refreshToken = await _secure.read(key: _refreshKey);
  }

  Future<void> setApiBase(String url) async {
    apiBase = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseKey, apiBase);
  }

  Future<void> setTokens(String? access, String? refresh) async {
    accessToken = access;
    refreshToken = refresh;
    if (access == null) {
      await _secure.delete(key: _accessKey);
    } else {
      await _secure.write(key: _accessKey, value: access);
    }
    if (refresh == null) {
      await _secure.delete(key: _refreshKey);
    } else {
      await _secure.write(key: _refreshKey, value: refresh);
    }
  }

  String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$apiBase$path';
  }

  Future<Map<String, dynamic>?> send(
    String method,
    String path, {
    Object? jsonBody,
    List<int>? bytes,
    String? contentType,
    bool retry = true,
  }) async {
    final headers = <String, String>{};
    if (accessToken != null) headers['Authorization'] = 'Bearer $accessToken';
    if (jsonBody != null) headers['Content-Type'] = 'application/json';
    if (contentType != null) headers['Content-Type'] = contentType;
    http.Response response;
    try {
      final uri = Uri.parse('$apiBase$path');
      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers);
      } else if (bytes != null) {
        response = await http.put(uri, headers: headers, body: bytes);
      } else {
        response = await http.post(uri, headers: headers, body: jsonBody == null ? null : jsonEncode(jsonBody));
      }
    } on SocketException {
      throw ApiException('Could not reach $apiBase. Set the API address to this computer\'s Wi-Fi address.');
    }
    if (response.statusCode == 401 && retry && refreshToken != null && !path.startsWith('/api/v1/auth/')) {
      final ok = await _refresh();
      if (ok) {
        return send(method, path, jsonBody: jsonBody, bytes: bytes, contentType: contentType, retry: false);
      }
    }
    if (response.statusCode >= 400) {
      var message = 'The request failed.';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] is Map) message = '${body['error']['message'] ?? message}';
      } catch (_) {}
      throw ApiException(message, status: response.statusCode);
    }
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.map((key, value) => MapEntry('$key', value));
    return {'value': decoded};
  }

  Future<bool> _refresh() async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode >= 400) {
        await setTokens(null, null);
        return false;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      await setTokens(body['accessToken'] as String?, body['refreshToken'] as String?);
      return accessToken != null;
    } catch (_) {
      await setTokens(null, null);
      return false;
    }
  }

  Future<List<int>> download(String url) async {
    final headers = <String, String>{};
    if (accessToken != null && url.startsWith(apiBase)) headers['Authorization'] = 'Bearer $accessToken';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode >= 400) throw ApiException('Could not download the file.', status: response.statusCode);
    return response.bodyBytes;
  }
}
