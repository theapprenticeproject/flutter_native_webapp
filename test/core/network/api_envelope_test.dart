import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';

import '../../support/fake_worker.dart';

/// The Worker answers {ok:true,data} or {ok:false,error:{code,message}}.
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  HttpClient clientFor(FakeWorkerAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    return HttpClient(SecureTokenStore(const FlutterSecureStorage()), dio: dio);
  }

  test('returns the data of an ok answer', () async {
    final adapter = FakeWorkerAdapter((_) => ok({'a': 1}));
    final data = await clientFor(adapter).postApi('/x', body: {'k': 'v'});
    expect(data, {'a': 1});
    expect(adapter.seen.single.body, {'k': 'v'});
  });

  test('turns an error answer into an ApiException with its code', () async {
    final adapter = FakeWorkerAdapter(
      (_) => failure(409, 'CONFLICT', 'cap reached'),
    );
    await expectLater(
      clientFor(adapter).postApi('/x'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'CONFLICT')
            .having((e) => e.status, 'status', 409),
      ),
    );
  });

  test('keeps the code when the status is 401, 404 or 429', () async {
    for (final (status, code) in [
      (401, 'UNAUTHORIZED'),
      (404, 'STUDENT_NOT_FOUND'),
      (429, 'RATE_LIMITED'),
    ]) {
      final adapter = FakeWorkerAdapter((_) => failure(status, code, 'm'));
      await expectLater(
        clientFor(adapter).postApi('/x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', code)),
      );
    }
  });

  test('a reply that is not the envelope becomes SERVER_ERROR', () async {
    final adapter = FakeWorkerAdapter((_) => (status: 502, body: 'oops'));
    await expectLater(
      clientFor(adapter).postApi('/x'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'SERVER_ERROR'),
      ),
    );
  });

  test('sends the active student token, or the token we pass', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = SecureTokenStore(const FlutterSecureStorage());
    await store.saveStudentSession(
      phoneToken: 'phone-tok',
      studentTokens: {'S1': 'tok-1', 'S2': 'tok-2'},
      activeStudentId: 'S2',
    );
    final adapter = FakeWorkerAdapter((_) => ok({}));
    final dio = Dio()..httpClientAdapter = adapter;
    final client = HttpClient(store, dio: dio);

    await client.postApi('/a');
    await client.postApi('/b', bearer: 'phone-tok');

    expect(adapter.seen[0].headers['Authorization'], 'Bearer tok-2');
    expect(adapter.seen[1].headers['Authorization'], 'Bearer phone-tok');
  });
}
