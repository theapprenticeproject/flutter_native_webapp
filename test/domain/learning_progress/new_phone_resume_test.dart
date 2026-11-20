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
import 'package:tapapp/domain/learning_progress/classroom_progress_stage.dart';
import 'package:tapapp/domain/learning_progress/unit_feedback.dart';
import 'package:tapapp/domain/program_content/course_detail_model.dart';
import 'package:tapapp/domain/progress/progress_repository.dart';
import 'package:tapapp/domain/submission/feedback_state.dart';
import 'package:tapapp/domain/submission/feedback_tracker.dart';
import 'package:tapapp/domain/submission/submission_repository.dart';

import '../../support/fake_worker.dart';

/// A student who already did work on the Worker opens the app on a NEW phone
/// (no saved steps). The app must show where the work stands (for example
/// "Pending: Feedback"), not the Watch step again. Otherwise the student would
/// send the work a second time.
CourseUnitModel _unit(int n) => CourseUnitModel(
  unitId: 'U-$n',
  name: 'Unit $n',
  description: '',
  requiredComponents: '',
  difficulty: '',
  xp: 0,
  videos: const [],
  assignments: [
    CourseAssignmentModel(
      id: 'a',
      sequence: 1,
      name: 'A',
      description: '',
      type: '',
      difficulty: '',
      steps: const [],
      assignmentId: 'AS-$n',
    ),
  ],
);

final _units = [_unit(1), _unit(2)];

Map<String, dynamic> _row(String result) => {
  'submission_id': 'SUB-1',
  'assignment_id_link': 'AS-1',
  'status': result == 'Pending' ? 'Processing' : 'Completed',
  'result_status': result,
  'attempt_number': 1,
  'attempts_remaining': 1,
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
  late FeedbackTracker tracker;
  Map<String, dynamic> syncAnswer = {};
  var submissions = <Map<String, dynamic>>[];

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tap_new_phone_');
    Hive.init(dir.path);
    values = await Hive.openBox<String>('values');
    indexes = await Hive.openBox<String>('indexes');
    cache = LocalCache.forTesting(values, indexes);
    submissions = [];
    syncAnswer = {};
    final worker = FakeWorkerAdapter(
      (r) => r.path == '/progress/sync'
          ? ok(syncAnswer)
          : ok({'submissions': submissions}),
    );
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = worker,
    );
    tracker = FeedbackTracker(SubmissionRepository(http), cache);
    learner = LearnerStateRepository(
      http,
      cache,
      progress: ProgressRepository(http),
      resolveCourse: (id) async => 'Course-A',
    );
    await cache.setForeverRawList(CacheKeys.linkRoster(), [
      {'student_id': 'S1', 'name': 'Asha', 'grade': '5', 'points': 10},
    ]);
    await learner.fetchState(learnerId: 'S1'); // a new phone: nothing saved
  });

  tearDown(() async {
    await values.close();
    await indexes.close();
    await dir.delete(recursive: true);
  });

  Future<UnitWithFeedback> openApp() async {
    await learner.refreshPoints('S1');
    return currentUnitWithFeedback(
      tracker: tracker,
      learner: learner,
      learnerId: 'S1',
      state: (await learner.readCached('S1'))!,
      units: _units,
    );
  }

  Map<String, dynamic> sync(
    String? activity, {
    String unit = 'U-1',
    String? sentFor,
  }) => {
    'changed': true,
    'updated_at': 5,
    'points': 10,
    'current_learning_unit': unit,
    'last_activity_type': activity,
    if (sentFor != null)
      'last_submission': {..._row('Pending'), 'assignment_id_link': sentFor},
  };

  test(
    'work sent, quiz graded, feedback pending: the pending screen',
    () async {
      // last_activity_type is "quiz" when the quiz is graded, whatever else.
      syncAnswer = sync('quiz');
      submissions = [_row('Pending')];

      final r = await openApp();

      expect(r.unitIndex, 0);
      expect(r.feedback, FeedbackStage.waiting);
      final snapshot = ClassroomProgressResolver.resolve(
        enrollment: r.state.enrollment!,
        unitIndex: r.unitIndex,
        unit: _units[0],
        feedback: r.feedback,
      );
      expect(snapshot.stage, ClassroomProgressStage.awaitingFeedback);
    },
  );

  test(
    'work sent but the quiz is not known: the quiz first, not Watch',
    () async {
      // "submission" does not say if the quiz is graded (the Worker shows
      // "quiz" first when it is), so the quiz stays open. If it was done, the
      // Worker answers a repeat and the student goes on.
      syncAnswer = sync('submission');
      submissions = [_row('Pending')];

      final r = await openApp();

      expect(r.feedback, FeedbackStage.waiting);
      expect(
        ClassroomProgressResolver.resolve(
          enrollment: r.state.enrollment!,
          unitIndex: r.unitIndex,
          unit: _units[0],
          feedback: r.feedback,
        ).stage,
        ClassroomProgressStage.takeQuiz,
      );
    },
  );

  test(
    'no step on the Worker, even with a work sent: Watch (video first)',
    () async {
      // A reset student: last_activity_type null, but the sync answer still
      // carries the work. The Worker refuses the quiz until the video is
      // recorded, so the student starts with the video.
      syncAnswer = sync(null, sentFor: 'AS-1');
      submissions = [_row('Pending')];

      final r = await openApp();

      expect(r.feedback, isNull);
      expect(
        ClassroomProgressResolver.resolve(
          enrollment: r.state.enrollment!,
          unitIndex: r.unitIndex,
          unit: _units[0],
        ).stage,
        ClassroomProgressStage.watchVideo,
      );
    },
  );

  test('only the video done on the Worker: the Make step, not Watch', () async {
    syncAnswer = sync('video');
    final r = await openApp();
    expect(r.feedback, FeedbackStage.notSent);
    expect(
      ClassroomProgressResolver.resolve(
        enrollment: r.state.enrollment!,
        unitIndex: r.unitIndex,
        unit: _units[0],
        feedback: r.feedback,
      ).stage,
      ClassroomProgressStage.submitProject,
    );
  });

  test('nothing done on the Worker: the Watch step', () async {
    syncAnswer = sync(null);
    final r = await openApp();
    expect(r.feedback, isNull);
    expect(
      ClassroomProgressResolver.resolve(
        enrollment: r.state.enrollment!,
        unitIndex: r.unitIndex,
        unit: _units[0],
      ).stage,
      ClassroomProgressStage.watchVideo,
    );
  });
}
