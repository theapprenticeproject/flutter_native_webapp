import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:tapapp/core/cache/cache_keys.dart';
import 'package:tapapp/core/cache/local_cache.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/learner/enrollment_model.dart';
import 'package:tapapp/domain/learner/learner_state_repository.dart';
import 'package:tapapp/domain/learning_progress/classroom_progress_stage.dart';
import 'package:tapapp/domain/program_content/bundled_course.dart';
import 'package:tapapp/domain/program_content/course_detail_model.dart';
import 'package:tapapp/domain/progress/progress_repository.dart';
import 'package:tapapp/l10n/gen/app_localizations.dart';
import 'package:tapapp/shared/errors/friendly_error.dart';

import '../../support/fake_worker.dart';

/// The Worker decides which unit a student is on (`current_learning_unit`, a
/// Learning Unit name such as `Unit -3-Coding with OctoStudio (TapApp)-62889`).
/// It rejects progress calls for a unit that is not the next in sequence, so the
/// app must start where the Worker says. If the id is not in the bundled course
/// the app shows a plain error: nobody reads logs in a browser.
CourseUnitModel _unit(String id) => CourseUnitModel(
  unitId: id,
  name: id,
  description: '',
  requiredComponents: '',
  difficulty: '',
  xp: 0,
  videos: const [],
  // The real units have an assignment: the submission step counts.
  assignments: [
    CourseAssignmentModel(
      id: 'a',
      sequence: 1,
      name: 'A',
      description: '',
      type: '',
      difficulty: '',
      steps: const [],
      assignmentId: 'AS-$id',
    ),
  ],
);

final _units = [
  for (final n in [1, 2, 3, 4]) _unit('Unit -$n-Course-A-$n'),
];

void main() {
  group('EnrollmentModel.alignedToUnit', () {
    EnrollmentModel e(int v, int q, int s) => EnrollmentModel(
      course: 'C',
      videosCompleted: v,
      quizzesCompleted: q,
      submissionIndex: s,
    );
    List<int> counts(EnrollmentModel m) => [
      m.videosCompleted,
      m.quizzesCompleted,
      m.submissionIndex,
    ];

    test('a new phone jumps to the Worker\'s unit, earlier units done', () {
      expect(counts(e(0, 0, 0).alignedToUnit(2)), [2, 2, 2]);
    });

    test('a unit the Worker says is open is never finished by the phone', () {
      // video, quiz and submission all done on the phone, but the Worker has
      // not closed the unit: valid feedback is what closes it (R-83).
      expect(counts(e(3, 3, 3).alignedToUnit(2)), [3, 3, 2]);
    });

    test('steps done in the open unit are kept', () {
      expect(counts(e(3, 2, 2).alignedToUnit(2)), [3, 2, 2]);
    });

    test('a phone far ahead of the Worker (a reset) goes back to it', () {
      expect(counts(e(6, 6, 6).alignedToUnit(1)), [1, 1, 1]);
    });

    test('the same place changes nothing', () {
      expect(counts(e(0, 0, 0).alignedToUnit(0)), [0, 0, 0]);
      expect(counts(e(1, 1, 1).alignedToUnit(1)), [1, 1, 1]);
    });

    test('the unit index after aligning is the Worker\'s unit', () {
      for (final start in [e(0, 0, 0), e(6, 6, 6), e(3, 3, 3), e(1, 0, 0)]) {
        final aligned = start.alignedToUnit(2);
        expect(
          ClassroomProgressResolver.resolveUnitIndexForCourse(aligned, _units),
          2,
        );
      }
    });
  });

  group('EnrollmentModel.alignedToUnit with the Worker\'s last activity', () {
    EnrollmentModel e(int v, int q, int s) => EnrollmentModel(
      course: 'C',
      videosCompleted: v,
      quizzesCompleted: q,
      submissionIndex: s,
    );
    List<int> counts(EnrollmentModel m) => [
      m.videosCompleted,
      m.quizzesCompleted,
      m.submissionIndex,
    ];
    List<int> at(int unit, String? last, [EnrollmentModel? from]) => counts(
      (from ?? e(0, 0, 0)).alignedToUnit(unit, known: true, lastActivity: last),
    );

    // The Worker's last_activity_type: video, quiz, submission or null.
    test('video: the video is done, nothing else', () {
      expect(at(2, 'video'), [3, 2, 2]);
    });

    test('quiz: the video and the quiz are done', () {
      expect(at(2, 'quiz'), [3, 3, 2]);
    });

    test('submission: the video is done; the quiz is not known, so open', () {
      expect(at(2, 'submission'), [3, 2, 2]);
    });

    test('null: nothing is done in this unit, whatever the phone says', () {
      expect(at(2, null), [2, 2, 2]);
      expect(at(2, null, e(3, 3, 3)), [2, 2, 2]);
    });

    test('the work is never closed by the phone: valid feedback does that', () {
      for (final last in ['video', 'quiz', 'submission', null]) {
        expect(at(2, last)[2], 2, reason: '$last');
      }
    });

    test('no answer from the Worker: the earlier rule still holds', () {
      expect(counts(e(3, 3, 3).alignedToUnit(2)), [3, 3, 2]);
    });

    test('the unit index is the Worker\'s unit for every activity', () {
      for (final last in ['video', 'quiz', 'submission', null]) {
        final m = e(0, 0, 0).alignedToUnit(2, known: true, lastActivity: last);
        expect(
          ClassroomProgressResolver.resolveUnitIndexForCourse(m, _units),
          2,
          reason: '$last',
        );
      }
    });
  });

  group('LearnerStateRepository.alignToWorkerUnit', () {
    late Directory dir;
    late Box<String> values;
    late Box<String> indexes;
    late LocalCache cache;
    late FakeWorkerAdapter adapter;
    late LearnerStateRepository repo;
    Object? syncUnit = 'Unit -3-Course-A-3';
    Object? syncActivity;
    String? syncSubmissionFor;
    var syncFails = false;

    setUp(() async {
      syncUnit = 'Unit -3-Course-A-3';
      syncActivity = null;
      syncSubmissionFor = null;
      syncFails = false;
      FlutterSecureStorage.setMockInitialValues({});
      dir = await Directory.systemTemp.createTemp('tap_worker_unit_');
      Hive.init(dir.path);
      values = await Hive.openBox<String>('values');
      indexes = await Hive.openBox<String>('indexes');
      cache = LocalCache.forTesting(values, indexes);
      await cache.setForeverRawList(CacheKeys.linkRoster(), [
        {
          'student_id': 'S1',
          'name': 'Asha',
          'grade': '5',
          'points': 0,
          'course_id': 'Course-A',
        },
      ]);
      adapter = FakeWorkerAdapter(
        (_) => syncFails
            ? failure(500, 'SERVER_ERROR', 'x')
            : ok({
                'changed': true,
                'updated_at': 9,
                'points': 5,
                'current_learning_unit': syncUnit,
                'last_activity_type': syncActivity,
                if (syncSubmissionFor != null)
                  'last_submission': {
                    'submission_id': 'SUB-1',
                    'assignment_id_link': syncSubmissionFor,
                    'status': 'Processing',
                    'result_status': 'Pending',
                    'attempt_number': 1,
                    'attempts_remaining': 1,
                  },
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
        resolveCourse: (id) async => id,
      );
      await repo.fetchState(learnerId: 'S1');
    });

    tearDown(() async {
      await values.close();
      await indexes.close();
      await dir.delete(recursive: true);
    });

    Future<int> indexAfterAlign() async {
      final state = await repo.alignToWorkerUnit('S1', _units);
      return ClassroomProgressResolver.resolveUnitIndexForCourse(
        state.enrollment!,
        _units,
      );
    }

    test('starts at the unit the Worker names', () async {
      await repo.refreshPoints('S1');
      expect(await indexAfterAlign(), 2);
    });

    test('an id that is not in the bundled course is an error', () async {
      syncUnit = 'LU-0088';
      await repo.refreshPoints('S1');
      await expectLater(
        repo.alignToWorkerUnit('S1', _units),
        throwsA(
          isA<UnitNotBundledException>().having(
            (e) => e.unitId,
            'unitId',
            'LU-0088',
          ),
        ),
      );
      // Nothing was changed by the failed attempt.
      final saved = await repo.readCached('S1');
      expect(saved!.enrollment!.videosCompleted, 0);
    });

    test('the student sees the plain "course not ready" message', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final f = describeError(const UnitNotBundledException('LU-0088'), en);
      expect(f.title, en.errorCourseNotReadyTitle);
      expect(f.action, ErrorAction.none);
      expect(f.message, isNot(contains('LU-0088')));
    });

    test(
      'no unit from the Worker (none assigned, or all done): keep going',
      () async {
        syncUnit = null;
        await repo.refreshPoints('S1');
        expect(await indexAfterAlign(), 0);
      },
    );

    test('a failed sync changes nothing, and does not throw', () async {
      syncFails = true;
      await repo.refreshPoints('S1');
      expect(await indexAfterAlign(), 0);
    });

    test(
      'an answer is used once: an old one never pulls the student back',
      () async {
        await repo.refreshPoints('S1');
        expect(await indexAfterAlign(), 2);
        // The student then finishes unit 3 on this phone. No new sync arrived.
        await repo.applyLocalProgress(learnerId: 'S1', xp: 1, videoIndex: 3);
        await repo.applyLocalProgress(learnerId: 'S1', xp: 1, quizIndex: 3);
        await repo.applyValidFeedback('S1', unitIndex: 2);
        expect(await indexAfterAlign(), 3);
      },
    );

    test(
      'steps saved for another unit are dropped when the unit changes',
      () async {
        await repo.applyLocalProgress(learnerId: 'S1', xp: 5, videoIndex: 1);
        expect(
          cache.getForeverRaw(CacheKeys.activityProgress('S1')),
          isNotNull,
        );
        await repo.refreshPoints('S1'); // the Worker says unit 3
        await repo.alignToWorkerUnit('S1', _units);
        expect(cache.getForeverRaw(CacheKeys.activityProgress('S1')), isNull);
      },
    );

    test(
      'steps saved for the same unit are kept when the Worker agrees',
      () async {
        syncUnit = 'Unit -1-Course-A-1';
        syncActivity = 'video';
        await repo.applyLocalProgress(learnerId: 'S1', xp: 5, videoIndex: 1);
        await repo.refreshPoints('S1');
        final state = await repo.alignToWorkerUnit('S1', _units);
        expect(state.enrollment!.videosCompleted, 1);
        expect(
          cache.getForeverRaw(CacheKeys.activityProgress('S1')),
          isNotNull,
        );
      },
    );

    test('the video the Worker already has is done on a new phone', () async {
      syncActivity = 'video';
      await repo.refreshPoints('S1');
      final state = await repo.alignToWorkerUnit('S1', _units);
      expect(state.enrollment!.videosCompleted, 3);
      expect(state.enrollment!.quizzesCompleted, 2);
      expect(state.enrollment!.submissionIndex, 2);
    });

    test('video and quiz the Worker already has are done too', () async {
      syncActivity = 'quiz';
      await repo.refreshPoints('S1');
      final state = await repo.alignToWorkerUnit('S1', _units);
      expect(state.enrollment!.videosCompleted, 3);
      expect(state.enrollment!.quizzesCompleted, 3);
    });

    test('a Worker with nothing in this unit wins over the phone', () async {
      // The phone says the video is done (for example after a reset).
      await repo.applyLocalProgress(learnerId: 'S1', xp: 5, videoIndex: 3);
      syncActivity = null;
      await repo.refreshPoints('S1');
      final state = await repo.alignToWorkerUnit('S1', _units);
      expect(state.enrollment!.videosCompleted, 2);
    });

    test(
      'no step recorded, but a work was sent for this unit: video done',
      () async {
        // The Worker only takes a work after the video, so the video is done.
        syncActivity = null;
        syncSubmissionFor = 'AS-Unit -3-Course-A-3';
        await repo.refreshPoints('S1');
        final state = await repo.alignToWorkerUnit('S1', _units);
        expect(state.enrollment!.videosCompleted, 3);
        expect(state.enrollment!.quizzesCompleted, 2);
        expect(state.enrollment!.submissionIndex, 2);
      },
    );

    test('a work sent for another unit says nothing about this one', () async {
      syncActivity = null;
      syncSubmissionFor = 'AS-Unit -1-Course-A-1';
      await repo.refreshPoints('S1');
      final state = await repo.alignToWorkerUnit('S1', _units);
      expect(state.enrollment!.videosCompleted, 2);
    });

    test(
      'the Worker\'s own last activity is not changed by a sent work',
      () async {
        syncActivity = 'quiz';
        syncSubmissionFor = 'AS-Unit -3-Course-A-3';
        await repo.refreshPoints('S1');
        final state = await repo.alignToWorkerUnit('S1', _units);
        expect(state.enrollment!.quizzesCompleted, 3);
      },
    );
  });
}
