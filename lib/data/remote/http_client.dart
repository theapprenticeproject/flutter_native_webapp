import 'package:dio/dio.dart';

import '../../core/cache/secure_token_store.dart';
import '../../core/constants/app_constants.dart';

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

  static String bucketForPath(String path) {
    if (path.startsWith('/auth/forgot-password/send-otp')) return 'otp';
    if (path.startsWith('/tapbuddy/chat') ||
        path.startsWith('/submission-review/review')) {
      return 'groq';
    }
    return 'default';
  }

  @override
  String toString() => 'RateLimitedException($bucket)';
}

class HttpClient {
  HttpClient(this._secureTokenStore) {
    _dio.options.baseUrl = AppConstants.workerBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 20);
    _dio.options.contentType = Headers.jsonContentType;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureTokenStore.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          await _persistTokenIfPresent(response.data);
          handler.next(response);
        },
        onError: (error, handler) async {
          await _persistTokenIfPresent(error.response?.data);
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio = Dio();
  final SecureTokenStore _secureTokenStore;

  Future<void> _persistTokenIfPresent(dynamic data) async {
    if (data is Map && data['token'] is String) {
      await _secureTokenStore.saveRefreshedToken(data['token'] as String);
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) => _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        queryParameters: method == 'GET' ? query : null,
        data: method == 'GET' ? null : body,
        options: Options(method: method),
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : const <String, dynamic>{};

      if (status == 401) {
        throw AuthException(
          map['error'] as String? ?? 'invalid_or_expired_token',
        );
      }
      if (status == 429) {
        throw RateLimitedException(RateLimitedException.bucketForPath(path));
      }
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
