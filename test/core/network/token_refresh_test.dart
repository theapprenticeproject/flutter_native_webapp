import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';

import '../../support/fake_worker.dart';

/// The student token lives 30 days and is never renewed by the Worker. When it
/// ends, a call answers UNAUTHORIZED. The app must ask `/auth/select_profile`
/// once, with the phone token, then try the same call again. Only if that fails
/// does the student need to open the link again.
void main() {
  late SecureTokenStore store;

  Future<void> signIn({String phoneToken = 'phone-tok'}) =>
      store.saveStudentSession(
        phoneToken: phoneToken,
        studentTokens: {'S1': 'old-tok'},
        activeStudentId: 'S1',
      );

  HttpClient clientFor(FakeWorkerAdapter adapter) =>
      HttpClient(store, dio: Dio()..httpClientAdapter = adapter);

  String? bearerOf(FakeRequest r) => r.headers['Authorization'] as String?;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = SecureTokenStore(const FlutterSecureStorage());
  });

  FakeWorkerAdapter worker({
    bool phoneTokenWorks = true,
    bool newTokenWorks = true,
  }) => FakeWorkerAdapter((r) {
    if (r.path == '/auth/select_profile') {
      return phoneTokenWorks && bearerOf(r) == 'Bearer phone-tok'
          ? ok({'token': 'new-tok'})
          : failure(401, 'UNAUTHORIZED', 'bad phone token');
    }
    final good = bearerOf(r) == 'Bearer new-tok' && newTokenWorks;
    return good ? ok({'changed': false}) : failure(401, 'UNAUTHORIZED', 'old');
  });

  test(
    'an expired student token is renewed once and the call is retried',
    () async {
      await signIn();
      final adapter = worker();

      final data = await clientFor(adapter).postApi('/progress/sync');

      expect(data['changed'], false);
      expect(adapter.seen.map((r) => r.path), [
        '/progress/sync',
        '/auth/select_profile',
        '/progress/sync',
      ]);
      expect(adapter.seen[1].body, {'student_id': 'S1'});
      expect(await store.readToken(), 'new-tok');
    },
  );

  test('the phone token is dead too: the original error is thrown', () async {
    await signIn();
    final adapter = worker(phoneTokenWorks: false);

    await expectLater(
      clientFor(adapter).postApi('/progress/sync'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'UNAUTHORIZED'),
      ),
    );
    expect(adapter.seen.where((r) => r.path == '/progress/sync'), hasLength(1));
    expect(await store.readToken(), 'old-tok');
  });

  test('no phone token saved: no renewal call, the error is thrown', () async {
    await signIn(phoneToken: '');
    final adapter = worker();

    await expectLater(
      clientFor(adapter).postApi('/progress/sync'),
      throwsA(isA<ApiException>()),
    );
    expect(adapter.seen.any((r) => r.path == '/auth/select_profile'), isFalse);
  });

  test('it retries only once, even if the new token is refused too', () async {
    await signIn();
    final adapter = worker(newTokenWorks: false);

    await expectLater(
      clientFor(adapter).postApi('/progress/sync'),
      throwsA(isA<ApiException>()),
    );
    expect(adapter.seen.where((r) => r.path == '/progress/sync'), hasLength(2));
    expect(
      adapter.seen.where((r) => r.path == '/auth/select_profile'),
      hasLength(1),
    );
  });

  test('calls at the same time share one renewal', () async {
    await signIn();
    final adapter = worker();
    final client = clientFor(adapter);

    await Future.wait([
      client.postApi('/progress/sync'),
      client.getApi('/gallery'),
      client.postApi('/progress/sync'),
    ]);

    expect(
      adapter.seen.where((r) => r.path == '/auth/select_profile'),
      hasLength(1),
    );
  });

  test(
    'a call with its own token, and the auth routes, are not renewed',
    () async {
      await signIn();
      final adapter = worker();
      final client = clientFor(adapter);

      await expectLater(
        client.postApi('/progress/sync', bearer: 'other'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        client.postApi('/auth/redeem', body: {'code': 'x'}),
        throwsA(isA<ApiException>()),
      );
      expect(
        adapter.seen.any((r) => r.path == '/auth/select_profile'),
        isFalse,
      );
    },
  );

  test('other errors are not renewed', () async {
    await signIn();
    final adapter = FakeWorkerAdapter((_) => failure(404, 'NOT_FOUND', 'x'));

    await expectLater(
      clientFor(adapter).postApi('/progress/sync'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NOT_FOUND')),
    );
    expect(adapter.seen, hasLength(1));
  });
}
