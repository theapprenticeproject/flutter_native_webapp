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
import 'package:tapapp/domain/program_content/bundled_course.dart';
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
        'course_id': 'Course-A',
      },
      {
        'student_id': 'S2',
        'name': 'Manu',
        'grade': '8',
        'points': 40,
        'course_id': 'Course-B',
      },
      {
        'student_id': 'S3',
        'name': 'Om',
        'grade': '3',
        'points': 0,
        'course_id': 'CRS-NOT-BUNDLED',
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
      resolveCourse: (id) async => resolveBundledCourse(id, bundled),
    );
  });

  tearDown(() async {
    await values.close();
    await indexes.close();
    await dir.delete(recursive: true);
  });

  test('first state is built from the login answer, with no request', () async {
    final state = await repo.fetchState(learnerId: 'S2');
    expect(adapter.seen, isEmpty);
    expect(state.xp, 40);
    expect(state.profile?.studentName, 'Manu');
    expect(state.enrollment?.course, 'Course-B');
    expect(state.enrollment?.videosCompleted, 0);
  });

  test(
    'a course that is not bundled is an error, and nothing is saved',
    () async {
      // S3 has `CRS-NOT-BUNDLED`: the app cannot show it.
      await expectLater(
        repo.fetchState(learnerId: 'S3'),
        throwsA(isA<CourseNotBundledException>()),
      );
      expect(await repo.readCached('S3'), isNull);
    },
  );

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

  // R-83: sending the work does not finish the submission step. Only valid
  // feedback does. If sending marked it done, the next unit would open early.
  test(
    'work sent: the points are kept, but the submission is not done',
    () async {
      await repo.fetchState(learnerId: 'S1');
      await repo.applyLocalProgress(learnerId: 'S1', xp: 10, videoIndex: 1);

      final state = await repo.applyLocalProgress(
        learnerId: 'S1',
        xp: 25,
        submissionIndex: 1,
        submissionSentOnly: true,
      );

      expect(state.enrollment?.submissionIndex, 0);
      expect(state.enrollment?.videosCompleted, 1);
      expect(state.pendingProgressXp, 35, reason: 'the 25 points are counted');
    },
  );

  test('valid feedback closes the submission step and the unit', () async {
    await repo.fetchState(learnerId: 'S1');
    await repo.applyLocalProgress(learnerId: 'S1', xp: 10, videoIndex: 1);
    await repo.applyLocalProgress(learnerId: 'S1', xp: 1, quizIndex: 1);

    final state = await repo.applyValidFeedback('S1', unitIndex: 0);

    expect(state.enrollment?.submissionIndex, 1);
    expect(state.enrollment?.quizzesCompleted, 1);
    expect(state.hasPendingLocalProgress, isFalse);
    expect(cache.has(CacheKeys.activityProgress('S1')), isFalse);
  });

  group('follows the Worker course', () {
    Future<void> workerSays(String studentId, String? course) async {
      await cache.setForeverRawList(CacheKeys.linkRoster(), [
        {
          'student_id': studentId,
          'name': 'Manu',
          'grade': '8',
          'points': 40,
          'course_id': course,
        },
      ]);
    }

    test('the same course as before: the saved progress stays', () async {
      await workerSays('S2', 'Course-B');
      await repo.fetchState(learnerId: 'S2');
      await repo.applyLocalProgress(learnerId: 'S2', xp: 10, videoIndex: 1);

      final again = await repo.fetchState(learnerId: 'S2');

      expect(again.enrollment?.course, 'Course-B');
      expect(again.enrollment?.videosCompleted, 1);
    });

    test(
      'the Worker moved the student to another course: start that course',
      () async {
        await workerSays('S2', 'Course-A');
        await repo.fetchState(learnerId: 'S2');
        await repo.applyLocalProgress(learnerId: 'S2', xp: 10, videoIndex: 1);

        await workerSays('S2', 'Course-B');
        final moved = await repo.fetchState(learnerId: 'S2');

        expect(moved.enrollment?.course, 'Course-B');
        expect(
          moved.enrollment?.videosCompleted,
          0,
          reason: 'a new course starts at unit 1',
        );
        expect(cache.has(CacheKeys.activityProgress('S2')), isFalse);
      },
    );

    test(
      'the new course is not bundled: an error, the old progress is kept',
      () async {
        await workerSays('S2', 'Course-A');
        await repo.fetchState(learnerId: 'S2');
        await repo.applyLocalProgress(learnerId: 'S2', xp: 10, videoIndex: 1);

        await workerSays('S2', 'Course-Z');
        await expectLater(
          repo.fetchState(learnerId: 'S2'),
          throwsA(isA<CourseNotBundledException>()),
        );
        expect((await repo.readCached('S2'))?.enrollment?.course, 'Course-A');
      },
    );

    test('the Worker sent no course at all: an error', () async {
      await workerSays('S2', null);
      await expectLater(
        repo.fetchState(learnerId: 'S2'),
        throwsA(isA<CourseNotBundledException>()),
      );
    });
  });
}
