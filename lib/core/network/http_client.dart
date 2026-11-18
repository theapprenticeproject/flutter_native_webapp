import 'dart:convert';

import 'package:dio/dio.dart';

import '../cache/secure_token_store.dart';
import '../constants/app_constants.dart';
import 'api_exception.dart';

class AuthException implements Exception {
  AuthException(this.code);
  final String code;

  bool get requiresReLogin =>
      code == 'token_phone_mismatch' || code == 'invalid_signature';

  @override
  String toString() => 'AuthException($code)';
}

class RateLimitedException implements Exception {
  RateLimitedException(this.bucket);
  final String bucket;

  static String bucketForPath(String path) => 'default';

  @override
  String toString() => 'RateLimitedException($bucket)';
}

class HttpClient {
  HttpClient(this._secureTokenStore, {Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = AppConstants.workerBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 20);
    _dio.options.contentType = Headers.jsonContentType;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureTokenStore.readToken();
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureTokenStore _secureTokenStore;

  /// Calls a route of the v1 Worker and returns its `data` object.
  ///
  /// The Worker answers `{"ok": true, "data": {...}}` or
  /// `{"ok": false, "error": {"code", "message"}}`. An error answer, or a
  /// reply that is not that envelope, throws an [ApiException]. A network
  /// failure still throws a `DioException`. Pass [bearer] to use another token
  /// than the active student's (for example the phone token).
  Future<Map<String, dynamic>> postApi(
    String path, {
    Map<String, dynamic>? body,
    String? bearer,
  }) => _sendApi('POST', path, body: body, bearer: bearer);

  Future<Map<String, dynamic>> getApi(
    String path, {
    Map<String, dynamic>? query,
    String? bearer,
  }) => _sendApi('GET', path, query: query, bearer: bearer);

  Future<Map<String, dynamic>> _sendApi(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? bearer,
  }) async {
    try {
      return await _sendOnce(method, path, query, body, bearer);
    } on ApiException catch (e) {
      // The student token lives 30 days and is never renewed by the Worker. Ask
      // for a new one with the phone token, then try the same call once more.
      // Auth routes and calls with their own token are never renewed.
      final canRenew =
          e.code == 'UNAUTHORIZED' &&
          bearer == null &&
          !path.startsWith('/auth/');
      if (!canRenew || !await _renewStudentToken()) rethrow;
      return _sendOnce(method, path, query, body, bearer);
    }
  }

  Future<bool>? _renewing;

  /// Calls at the same time share one renewal. Returns false when the phone
  /// token is missing or refused: the student must open the link again.
  Future<bool> _renewStudentToken() =>
      _renewing ??= _renew().whenComplete(() => _renewing = null);

  Future<bool> _renew() async {
    try {
      final studentId = await _secureTokenStore.readActiveStudentId();
      final phoneToken = await _secureTokenStore.readPhoneToken();
      if (studentId == null || phoneToken == null || phoneToken.isEmpty) {
        return false;
      }
      final data = await _sendOnce('POST', '/auth/select_profile', null, {
        'student_id': studentId,
      }, phoneToken);
      final token = data['token'];
      if (token is! String) return false;
      await _secureTokenStore.saveStudentToken(studentId, token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _sendOnce(
    String method,
    String path,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? bearer,
  ) async {
    final response = await _dio.request<dynamic>(
      path,
      queryParameters: method == 'GET' ? query : null,
      data: method == 'GET' ? null : (body ?? const <String, dynamic>{}),
      options: Options(
        method: method,
        headers: bearer == null ? null : {'Authorization': 'Bearer $bearer'},
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );
    final status = response.statusCode;
    final envelope = _decodeEnvelope(response.data);

    if (envelope != null && envelope['ok'] == true) {
      final data = envelope['data'];
      return data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
    }
    final error = envelope?['error'];
    if (error is Map) {
      throw ApiException(
        (error['code'] as String?) ?? 'SERVER_ERROR',
        (error['message'] as String?) ?? '',
        status: status,
      );
    }
    throw ApiException('SERVER_ERROR', 'unexpected reply', status: status);
  }

  /// Decodes the reply, or returns null if it is not a JSON object (for
  /// example an HTML error page from a proxy).
  Map<String, dynamic>? _decodeEnvelope(dynamic raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }
}
