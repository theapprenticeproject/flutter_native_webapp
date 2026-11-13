import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/progress/progress_repository.dart';
import 'package:tapapp/domain/progress/step_recorder.dart';

import '../../support/fake_worker.dart';

Map<String, dynamic> _awarded({bool repeat = false}) => {
  'points_awarded': repeat ? 10 : 10,
  'points_total': 310,
  'points_tier': 'bronze',
  'updated_at': 1,
  'repeat': repeat,
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  StepRecorder recorderFor(FakeWorkerAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: dio,
    );
    return StepRecorder(ProgressRepository(http), studentId: 'S1');
  }

  test('records the video and returns the points the Worker gave', () async {
    final adapter = FakeWorkerAdapter((_) => ok(_awarded()));
    final record = await recorderFor(
      adapter,
    ).recordVideo(unitId: 'U1', videoId: 'V1');

    expect(record.pointsAwarded, 10);
    expect(record.pointsTotal, 310);
    expect(record.alreadyRecorded, isFalse);
    expect(adapter.seen.single.body!['unit_id'], 'U1');
    expect(adapter.seen.single.body!['video_id'], 'V1');
    expect(adapter.seen.single.body!['watched'], true);
  });

  test('a retry after a network failure sends the SAME key', () async {
    var calls = 0;
    final adapter = FakeWorkerAdapter((_) {
      calls++;
      return calls == 1 ? (status: 502, body: 'bad gateway') : ok(_awarded());
    });
    final recorder = recorderFor(adapter);

    await expectLater(
      recorder.recordVideo(unitId: 'U1', videoId: 'V1'),
      throwsA(anything),
    );
    await recorder.recordVideo(unitId: 'U1', videoId: 'V1');

    final keys = adapter.seen.map((r) => r.body!['idempotency_key']).toList();
    expect(keys, hasLength(2));
    expect(keys[0], keys[1], reason: 'the key must be kept until it works');
  });

  test(
    'a repeat answer keeps the original points (our retry succeeded)',
    () async {
      final adapter = FakeWorkerAdapter((_) => ok(_awarded(repeat: true)));
      final record = await recorderFor(
        adapter,
      ).recordVideo(unitId: 'U1', videoId: 'V1');
      expect(record.alreadyRecorded, isTrue);
      expect(
        record.pointsAwarded,
        10,
        reason: 'the first request earned them, the answer was lost',
      );
    },
  );

  test(
    'CONFLICT means the video was marked before: go on, no points',
    () async {
      final adapter = FakeWorkerAdapter(
        (_) => failure(409, 'CONFLICT', 'cap reached'),
      );
      final record = await recorderFor(
        adapter,
      ).recordVideo(unitId: 'U1', videoId: 'V1');
      expect(record.alreadyRecorded, isTrue);
      expect(record.pointsAwarded, 0);
      expect(record.pointsTotal, isNull);
    },
  );

  test('other Worker errors are thrown so the Retry button shows', () async {
    final adapter = FakeWorkerAdapter(
      (_) => failure(502, 'UPSTREAM_ERROR', 'down'),
    );
    await expectLater(
      recorderFor(adapter).recordVideo(unitId: 'U1', videoId: 'V1'),
      throwsA(anything),
    );
  });

  test('a different video gets a different key', () async {
    final adapter = FakeWorkerAdapter((_) => ok(_awarded()));
    final recorder = recorderFor(adapter);
    await recorder.recordVideo(unitId: 'U1', videoId: 'V1');
    await recorder.recordVideo(unitId: 'U2', videoId: 'V2');
    expect(
      adapter.seen[0].body!['idempotency_key'],
      isNot(adapter.seen[1].body!['idempotency_key']),
    );
  });

  test('once recorded, asking again does not call the Worker again', () async {
    final adapter = FakeWorkerAdapter((_) => ok(_awarded()));
    final recorder = recorderFor(adapter);
    await recorder.recordVideo(unitId: 'U1', videoId: 'V1');
    final again = await recorder.recordVideo(unitId: 'U1', videoId: 'V1');
    expect(adapter.seen, hasLength(1));
    expect(again.pointsAwarded, 10);
  });
}
