import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:tapapp/core/cache/local_cache.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/submission/feedback_state.dart';
import 'package:tapapp/domain/submission/feedback_tracker.dart';
import 'package:tapapp/domain/submission/submission_repository.dart';

import '../../support/fake_worker.dart';

Map<String, dynamic> _row({
  String assignment = 'AS-1',
  String status = 'Pending',
  String result = 'Pending',
  int? score,
  String createdAt = '2026-11-16T08:00:00Z',
}) => {
  'submission_id': 'SUB-1',
  'assignment_id_link': assignment,
  'status': status,
  'result_status': result,
  'score': score,
  'attempt_number': 1,
  'attempts_remaining': 1,
  'created_at': createdAt,
};

void main() {
  late Directory dir;
  late Box<String> values;
  late Box<String> indexes;
  late LocalCache cache;
  final now = DateTime.utc(2026, 11, 16, 12);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tap_feedback_');
    Hive.init(dir.path);
    values = await Hive.openBox<String>('values');
    indexes = await Hive.openBox<String>('indexes');
    cache = LocalCache.forTesting(values, indexes);
  });

  tearDown(() async {
    await values.close();
    await indexes.close();
    await dir.delete(recursive: true);
  });

  FeedbackTracker trackerFor(FakeWorkerAdapter worker) {
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = worker,
    );
    return FeedbackTracker(SubmissionRepository(http), cache);
  }

  test('nothing sent: not sent', () async {
    final tracker = trackerFor(
      FakeWorkerAdapter((_) => ok({'submissions': []})),
    );
    final check = await tracker.check('S1', 'AS-1', now: now);
    expect(check?.stage, FeedbackStage.notSent);
    expect(check?.submission, isNull);
  });

  test('pending: waiting, and the answer is kept', () async {
    final tracker = trackerFor(
      FakeWorkerAdapter(
        (_) => ok({
          'submissions': [_row()],
        }),
      ),
    );
    final check = await tracker.check('S1', 'AS-1', now: now);
    expect(check?.stage, FeedbackStage.waiting);
    expect(
      tracker.cached('S1', 'AS-1', now: now)?.stage,
      FeedbackStage.waiting,
    );
  });

  test(
    'graded and valid: valid, with the submission for the Results chat',
    () async {
      final tracker = trackerFor(
        FakeWorkerAdapter(
          (_) => ok({
            'submissions': [
              _row(
                status: 'Completed',
                result: 'Success - Original',
                score: 80,
              ),
            ],
          }),
        ),
      );
      final check = await tracker.check('S1', 'AS-1', now: now);
      expect(check?.stage, FeedbackStage.valid);
      expect(check?.submission?.score, 80);
    },
  );

  test('offline: the last known state is used', () async {
    final online = trackerFor(
      FakeWorkerAdapter(
        (_) => ok({
          'submissions': [_row()],
        }),
      ),
    );
    await online.check('S1', 'AS-1', now: now);

    final offline = trackerFor(
      FakeWorkerAdapter((_) => (status: 502, body: 'x')),
    );
    final check = await offline.check('S1', 'AS-1', now: now);
    expect(check?.stage, FeedbackStage.waiting);
  });

  test('offline for a long time: a waiting state becomes slow', () async {
    final online = trackerFor(
      FakeWorkerAdapter(
        (_) => ok({
          'submissions': [_row()],
        }),
      ),
    );
    await online.check('S1', 'AS-1', now: now);

    final offline = trackerFor(
      FakeWorkerAdapter((_) => (status: 502, body: 'x')),
    );
    final later = now.add(const Duration(hours: 30));
    expect(
      (await offline.check('S1', 'AS-1', now: later))?.stage,
      FeedbackStage.slow,
    );
  });

  test('offline and never checked: unknown (null), not "not sent"', () async {
    final tracker = trackerFor(
      FakeWorkerAdapter((_) => (status: 502, body: 'x')),
    );
    expect(await tracker.check('S1', 'AS-1', now: now), isNull);
  });

  test(
    'right after sending, the state is waiting even before the Worker answers',
    () async {
      final tracker = trackerFor(
        FakeWorkerAdapter((_) => (status: 502, body: 'x')),
      );
      await tracker.markSent('S1', 'AS-1', now: now);
      final check = await tracker.check('S1', 'AS-1', now: now);
      expect(check?.stage, FeedbackStage.waiting);
    },
  );

  test('students and assignments do not share a saved state', () async {
    final tracker = trackerFor(
      FakeWorkerAdapter((_) => (status: 502, body: 'x')),
    );
    await tracker.markSent('S1', 'AS-1', now: now);
    expect(tracker.cached('S2', 'AS-1', now: now), isNull);
    expect(tracker.cached('S1', 'AS-2', now: now), isNull);
  });
}
