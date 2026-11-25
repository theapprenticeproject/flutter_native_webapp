import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/tap_buddy/tap_buddy_repository.dart';

import '../../support/fake_worker.dart';

/// `POST /tapbuddy/chat` (API reference v7, section 7).
TapBuddyRepository _repo(FakeWorkerAdapter adapter) => TapBuddyRepository(
  HttpClient(
    SecureTokenStore(const FlutterSecureStorage()),
    dio: Dio()..httpClientAdapter = adapter,
  ),
);

void main() {
  test(
    'sends the message with the screen context and returns the reply',
    () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok({'reply': 'Tap Add my work.'}),
      );
      final reply = await _repo(adapter).ask(
        'How do I send my photo?',
        context: {'language': 'hi', 'step': 'make'},
      );
      expect(reply, 'Tap Add my work.');
      expect(adapter.seen.single.path, '/tapbuddy/chat');
      expect(adapter.seen.single.body, {
        'message': 'How do I send my photo?',
        'context': {'language': 'hi', 'step': 'make'},
      });
    },
  );

  test('the Worker\'s error codes come through', () async {
    for (final code in ['RATE_LIMITED', 'UPSTREAM_ERROR']) {
      final adapter = FakeWorkerAdapter((_) => failure(429, code, 'x'));
      await expectLater(
        _repo(adapter).ask('hi', context: const {}),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', code)),
      );
    }
  });
}
