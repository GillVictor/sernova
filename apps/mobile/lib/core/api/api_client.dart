import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Returns the current access token, or null when signed out.
/// Sign-in, rotation and refresh belong to FR-01 (S1-T3); this client only
/// attaches whatever token it is given.
typedef AccessTokenProvider = FutureOr<String?> Function();

/// Minimal JSON client for /api/v1.
class ApiClient {
  ApiClient({
    required Uri baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
    bool allowInsecure = false,
    this.accessToken,
  })  : _baseUrl = _normalize(baseUrl),
        _http = httpClient ?? http.Client() {
    if (_baseUrl.scheme != 'https' && !allowInsecure) {
      throw const ConfigException();
    }
  }

  final Uri _baseUrl;
  final http.Client _http;
  final Duration timeout;
  final AccessTokenProvider? accessToken;

  static Uri _normalize(Uri u) {
    final path = u.path.endsWith('/') ? u.path.substring(0, u.path.length - 1) : u.path;
    return u.replace(path: path);
  }

  Future<Object?> getJson(String path, {Map<String, String> query = const {}}) =>
      _send('GET', path, query: query);

  Future<Object?> postJson(String path, {Object? body}) => _send('POST', path, body: body);

  Future<Object?> patchJson(String path, {Object? body}) => _send('PATCH', path, body: body);

  Future<Object?> putJson(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String> query = const {},
    Object? body,
  }) async {
    final uri = _baseUrl.replace(
      path: '${_baseUrl.path}$path',
      queryParameters: query.isEmpty ? null : query,
    );
    final req = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Accept-Language'] = 'fr';
    final token = await accessToken?.call();
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      req.headers['Content-Type'] = 'application/json; charset=utf-8';
      req.body = jsonEncode(body);
    }

    final http.Response res;
    try {
      res = await _http.send(req).then(http.Response.fromStream).timeout(timeout);
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } catch (_) {
      // SocketException etc. (dart:io is avoided to stay web-safe).
      throw const NetworkException();
    }

    if (res.statusCode >= 400) throw _toApiException(res);
    if (res.bodyBytes.isEmpty) return null; // 204
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw ApiException(status: res.statusCode, code: 'UNKNOWN');
    }
  }

  ApiException _toApiException(http.Response res) {
    String code = 'UNKNOWN';
    String? traceId;
    var fieldErrors = <FieldError>[];
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map<String, dynamic>) {
        final c = body['code'];
        if (c is String && c.isNotEmpty) code = c;
        final t = body['traceId'];
        if (t is String) traceId = t;
        final errs = body['errors'];
        if (errs is List) {
          fieldErrors = [
            for (final e in errs)
              if (e is Map<String, dynamic> && e['field'] is String && e['code'] is String)
                FieldError(field: e['field'] as String, code: e['code'] as String),
          ];
        }
      }
    } catch (_) {
      // Not problem+json: keep UNKNOWN.
    }
    return ApiException(
      status: res.statusCode,
      code: code,
      fieldErrors: fieldErrors,
      retryAfterSeconds: int.tryParse(res.headers['retry-after'] ?? ''),
      traceId: traceId,
    );
  }

  void close() => _http.close();
}
