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
import 'package:tapapp/domain/learning_progress/unit_feedback.dart';
import 'package:tapapp/domain/program_content/course_detail_model.dart';
import 'package:tapapp/domain/submission/feedback_state.dart';
import 'package:tapapp/domain/submission/feedback_tracker.dart';
import 'package:tapapp/domain/submission/submission_repository.dart';

import '../../support/fake_worker.dart';

CourseUnitModel _unit({String assignmentId = 'AS-1'}) => CourseUnitModel(
  name: 'U',
  description: '',
  requiredComponents: '',
  difficulty: '',
  xp: 0,
  videos: const [],
  assignments: assignmentId.isEmpty
      ? const []
      : [
          CourseAssignmentModel(
            id: 'a',
            sequence: 1,
            name: 'A',
            description: '',
            type: '',
            difficulty: '',
            steps: const [],
            assignmentId: assignmentId,
          ),
        ],
);

Map<String, dynamic> _row(String result, int? score) => {
  'submission_id': 'SUB-1',
  'assignment_id_link': 'AS-1',
  'status': result == 'Pending' ? 'Pending' : 'Completed',
  'result_status': result,
  'score': score,
  'attempt_number': 1,
  'attempts_remaining': 1,
  // An hour ago, so the work is "waiting" and never "slow" whatever day the
  // test runs (these tests use the real clock).
  'created_at': DateTime.now()
      .toUtc()
      .subtract(const Duration(hours: 1))
      .toIso8601String(),
};

void main() {
  late Directory dir;
  late Box<String> values;
  late Box<String> indexes;
  late LocalCache cache;
  late LearnerStateRepository learner;
  late FakeWorkerAdapter worker;
  late FeedbackTracker tracker;
  var rows = <Map<String, dynamic>>[];

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tap_unit_feedback_');
    Hive.init(dir.path);
    values = await Hive.openBox<String>('values');
    indexes = await Hive.openBox<String>('indexes');
    cache = LocalCache.forTesting(values, indexes);
    rows = [];
    worker = FakeWorkerAdapter((_) => ok({'submissions': rows}));
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = worker,
    );
    tracker = FeedbackTracker(SubmissionRepository(http), cache);
    learner = LearnerStateRepository(
      http,
      cache,
      resolveCourse: (id) async => 'Course-A',
    );
    await cache.setForeverRawList(CacheKeys.linkRoster(), [
      {'student_id': 'S1', 'name': 'Asha', 'grade': '5', 'points': 0},
    ]);
    await learner.fetchState(learnerId: 'S1');
  });

  tearDown(() async {
    await values.close();
    await indexes.close();
    await dir.delete(recursive: true);
  });

  Future<FeedbackStage?> load({CourseUnitModel? unit, bool videoDone = true}) =>
      loadUnitFeedback(
        tracker: tracker,
        learner: learner,
        learnerId: 'S1',
        unit: unit ?? _unit(),
        unitIndex: 0,
        videoDone: videoDone,
      );

  test('the video is not watched yet: nothing was sent, no request', () async {
    expect(await load(videoDone: false), isNull);
    expect(worker.seen, isEmpty);
  });

  test('a unit with no assignment: no request', () async {
    expect(await load(unit: _unit(assignmentId: '')), isNull);
    expect(worker.seen, isEmpty);
  });

  test('nothing sent: not sent', () async {
    expect(await load(), FeedbackStage.notSent);
  });

  test('pending: waiting, and the unit stays open', () async {
    rows = [_row('Pending', null)];
    expect(await load(), FeedbackStage.waiting);
    expect((await learner.readCached('S1'))?.enrollment?.submissionIndex, 0);
  });

  test(
    'valid and the quiz done: the unit stays open until the Results chat',
    () async {
      await learner.applyLocalProgress(learnerId: 'S1', xp: 0, videoIndex: 1);
      await learner.applyLocalProgress(learnerId: 'S1', xp: 0, quizIndex: 1);
      rows = [_row('Success - Original', 80)];

      expect(await load(), FeedbackStage.valid);
      expect((await learner.readCached('S1'))?.enrollment?.submissionIndex, 0);
    },
  );

  test('not valid: the unit stays open', () async {
    rows = [_row('Success - Flagged', 40)];
    expect(await load(), FeedbackStage.notValid);
    expect((await learner.readCached('S1'))?.enrollment?.submissionIndex, 0);
  });

  test('the Worker cannot be reached and nothing is saved: unknown', () async {
    worker = FakeWorkerAdapter((_) => (status: 502, body: 'x'));
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = worker,
    );
    tracker = FeedbackTracker(SubmissionRepository(http), cache);
    expect(await load(), isNull);
  });

  group('the current unit with its feedback', () {
    final units = [_unit(), _unit(assignmentId: 'AS-2')];

    Future<UnitWithFeedback> current() async => currentUnitWithFeedback(
      tracker: tracker,
      learner: learner,
      learnerId: 'S1',
      state: (await learner.readCached('S1'))!,
      units: units,
    );

    test('a new student: the first unit, nothing to ask yet', () async {
      final r = await current();
      expect(r.unitIndex, 0);
      expect(r.feedback, isNull);
      expect(worker.seen, isEmpty);
    });

    test('work sent and waiting: the same unit stays current', () async {
      await learner.applyLocalProgress(learnerId: 'S1', xp: 0, videoIndex: 1);
      await learner.applyLocalProgress(learnerId: 'S1', xp: 0, quizIndex: 1);
      rows = [_row('Pending', null)];

      final r = await current();
      expect(r.unitIndex, 0);
      expect(r.feedback, FeedbackStage.waiting);
    });

    test(
      'valid feedback: the same unit stays current for the Results chat',
      () async {
        await learner.applyLocalProgress(learnerId: 'S1', xp: 0, videoIndex: 1);
        await learner.applyLocalProgress(learnerId: 'S1', xp: 0, quizIndex: 1);
        rows = [_row('Success - Original', 80)];

        final r = await current();
        expect(r.unitIndex, 0);
        expect(r.feedback, FeedbackStage.valid);
      },
    );

    test('after the Results chat the next unit is current', () async {
      await learner.applyLocalProgress(learnerId: 'S1', xp: 0, videoIndex: 1);
      await learner.applyLocalProgress(learnerId: 'S1', xp: 0, quizIndex: 1);
      await learner.applyValidFeedback('S1', unitIndex: 0);
      rows = [_row('Success - Original', 80)];

      final r = await current();
      expect(r.unitIndex, 1);
      expect(r.feedback, isNull, reason: 'the next unit has nothing sent');
    });

    test(
      'the video done, work not sent (postponed): the Make step is next',
      () async {
        await learner.applyLocalProgress(learnerId: 'S1', xp: 0, videoIndex: 1);
        final r = await current();
        expect(r.unitIndex, 0);
        expect(r.feedback, FeedbackStage.notSent);
      },
    );
  });
}
