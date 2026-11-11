import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A fake Worker for tests. It answers each request from a handler and keeps
/// the requests it saw, so a test can check the path, the headers and the body.
class FakeRequest {
  FakeRequest(this.method, this.path, this.headers, this.body);
  final String method;
  final String path;
  final Map<String, dynamic> headers;
  final Map<String, dynamic>? body;
}

typedef FakeHandler = ({int status, Object body}) Function(FakeRequest r);

class FakeWorkerAdapter implements HttpClientAdapter {
  FakeWorkerAdapter(this.handler);

  final FakeHandler handler;
  final List<FakeRequest> seen = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final raw = options.data;
    final request = FakeRequest(
      options.method,
      options.path,
      Map<String, dynamic>.from(options.headers),
      raw is Map ? Map<String, dynamic>.from(raw) : null,
    );
    seen.add(request);
    final reply = handler(request);
    return ResponseBody.fromString(
      reply.body is String ? reply.body as String : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({int status, Object body}) ok(Map<String, dynamic> data) =>
    (status: 200, body: {'ok': true, 'data': data});

({int status, Object body}) failure(int status, String code, String message) =>
    (
      status: status,
      body: {
        'ok': false,
        'error': {'code': code, 'message': message},
      },
    );
