import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:tapapp/core/cache/cache_keys.dart';
import 'package:tapapp/core/cache/local_cache.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/learner/learner_state_repository.dart';
import 'package:tapapp/domain/progress/progress_repository.dart';

import '../../support/fake_worker.dart';

/// The learner state in v1 comes from the login answer and the Worker's points.
/// The unit and step are kept on the phone (the app follows the bundled order).
void main() {
  late Directory dir;
  late Box<String> values;
  late Box<String> indexes;
  late LocalCache cache;
  late FakeWorkerAdapter adapter;
  late LearnerStateRepository repo;

  const bundled = ['Course-A', 'Course-B'];

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tap_state_v1_');
    Hive.init(dir.path);
    values = await Hive.openBox<String>('values');
    indexes = await Hive.openBox<String>('indexes');
    cache = LocalCache.forTesting(values, indexes);
    await cache.setForeverRawList(CacheKeys.linkRoster(), [
      {
        'student_id': 'S1',
        'name': 'Asha New',
        'grade': '5',
        'points': 300,
        'course_id': 'CRS-NOT-BUNDLED',
      },
      {
        'student_id': 'S2',
        'name': 'Manu',
        'grade': '8',
        'points': 40,
        'course_id': 'Course-B',
      },
    ]);
    adapter = FakeWorkerAdapter(
      (_) => ok({
        'changed': true,
        'updated_at': 9,
        'points': 412,
        'points_tier': 'bronze',
      }),
    );
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = adapter,
    );
    repo = LearnerStateRepository(
      http,
      cache,
      progress: ProgressRepository(http),
      resolveCourse: (id) async => bundled.contains(id) ? id : bundled.first,
    );
  });

  tearDown(() async {
    await values.close();
    await indexes.close();
    await dir.delete(recursive: true);
  });

  test('first state is built from the login answer, with no request', () async {
    final state = await repo.fetchState(learnerId: 'S1');
    expect(adapter.seen, isEmpty);
    expect(state.xp, 300);
    expect(state.profile?.studentName, 'Asha New');
    expect(
      state.enrollment?.course,
      'Course-A',
      reason: 'an unknown course falls back to the first bundled course',
    );
    expect(state.enrollment?.videosCompleted, 0);
  });

  test('a known bundled course id is kept', () async {
    final state = await repo.fetchState(learnerId: 'S2');
    expect(state.enrollment?.course, 'Course-B');
  });

  test('a saved state is returned as it is, with no request', () async {
    await repo.fetchState(learnerId: 'S1');
    final again = await repo.fetchState(learnerId: 'S1');
    expect(again.xp, 300);
    expect(adapter.seen, isEmpty);
  });

  test(
    'refreshing takes the points from sync and keeps the progress',
    () async {
      await repo.fetchState(learnerId: 'S1');
      await repo.applyLocalProgress(learnerId: 'S1', xp: 10, videoIndex: 1);

      final state = await repo.fetchState(learnerId: 'S1', forceRefresh: true);

      expect(adapter.seen.single.path, '/progress/sync');
      expect(state.xp, 412);
      expect(
        state.enrollment?.videosCompleted,
        1,
        reason: 'the unit step on the phone is not lost',
      );
    },
  );

  test('applyServerPoints saves the total the Worker gave', () async {
    await repo.fetchState(learnerId: 'S1');
    await repo.applyServerPoints('S1', 310);
    expect((await repo.readCached('S1'))?.xp, 310);
  });

  test(
    'finishing a unit is local: no request, progress kept, flags cleared',
    () async {
      await repo.fetchState(learnerId: 'S1');
      await repo.applyLocalProgress(learnerId: 'S1', xp: 10, videoIndex: 1);
      await repo.applyLocalProgress(learnerId: 'S1', xp: 1, quizIndex: 1);
      await repo.applyLocalProgress(
        learnerId: 'S1',
        xp: 25,
        submissionIndex: 1,
      );

      final done = await repo.completeUnitLocally('S1');

      expect(adapter.seen, isEmpty);
      expect(done.hasPendingLocalProgress, isFalse);
      expect(done.pendingProgressXp, 0);
      expect(done.enrollment?.videosCompleted, 1);
      expect(done.enrollment?.quizzesCompleted, 1);
      expect(done.enrollment?.submissionIndex, 1);
      expect(cache.has(CacheKeys.activityProgress('S1')), isFalse);
      final saved = await repo.readCached('S1');
      expect(saved?.enrollment?.videosCompleted, 1);
    },
  );
}
