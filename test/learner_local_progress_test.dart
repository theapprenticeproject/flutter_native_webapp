import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:tapapp/core/cache/cache_keys.dart';
import 'package:tapapp/core/cache/local_cache.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/data/remote/http_client.dart';
import 'package:tapapp/data/repositories/learner_state_repository.dart';
import 'package:tapapp/models/classroom_progress_stage.dart';
import 'package:tapapp/models/learner_state_model.dart';

void main() {
  late Directory tempDirectory;
  late Box<String> valueBox;
  late Box<String> indexBox;
  late LocalCache cache;
  late LearnerStateRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('tap_progress_test_');
    Hive.init(tempDirectory.path);
    valueBox = await Hive.openBox<String>('values');
    indexBox = await Hive.openBox<String>('indexes');
    cache = LocalCache.forTesting(valueBox, indexBox);
    repository = LearnerStateRepository(
      HttpClient(SecureTokenStore(const FlutterSecureStorage())),
      cache,
    );
  });

  tearDown(() async {
    await valueBox.close();
    await indexBox.close();
    await tempDirectory.delete(recursive: true);
  });

  LearnerStateModel serverState(String learnerId, {int videosCompleted = 0}) =>
      LearnerStateModel.fromFullJson(learnerId, {
        'enrollment': {
          'course': 'course-1',
          'videos_completed': videosCompleted,
          'submission_index': 0,
          'quizzes_completed': 0,
        },
      });

  test(
    'restores the exact local stage without leaking across learners',
    () async {
      final learnerA = serverState('learner-a');
      final learnerB = serverState('learner-b', videosCompleted: 4);
      await cache.setForeverRaw(
        CacheKeys.learnerState('learner-a'),
        learnerA.toJson(),
      );
      await cache.setForeverRaw(
        CacheKeys.learnerState('learner-b'),
        learnerB.toJson(),
      );

      await repository.applyLocalProgress(
        learnerId: 'learner-a',
        videoIndex: 1,
        xp: 10,
      );
      final afterSubmission = await repository.applyLocalProgress(
        learnerId: 'learner-a',
        submissionIndex: 1,
        xp: 20,
      );

      expect(afterSubmission.enrollment!.videosCompleted, 1);
      expect(afterSubmission.enrollment!.submissionIndex, 1);
      expect(afterSubmission.enrollment!.quizzesCompleted, 0);
      expect(
        ClassroomProgressResolver.resolve(
          enrollment: afterSubmission.enrollment!,
          unitIndex: 0,
        ).stage,
        ClassroomProgressStage.takeQuiz,
      );

      await cache.setForeverRaw(
        CacheKeys.learnerState('learner-a'),
        learnerA.toJson(),
      );
      final restoredA = await repository.restoreLocalProgress(
        await repository.readCached('learner-a') as LearnerStateModel,
      );
      final restoredB = await repository.restoreLocalProgress(
        await repository.readCached('learner-b') as LearnerStateModel,
      );

      expect(restoredA.enrollment!.submissionIndex, 1);
      expect(restoredA.enrollment!.quizzesCompleted, 0);
      expect(restoredB.enrollment!.submissionIndex, 0);
      expect(restoredB.enrollment!.videosCompleted, 4);

      final nextUnit = await repository.prepareLocalUnit(
        learnerId: 'learner-a',
        unitIndex: 1,
      );
      expect(nextUnit.enrollment!.videosCompleted, 1);
      expect(nextUnit.enrollment!.submissionIndex, 1);
      expect(nextUnit.enrollment!.quizzesCompleted, 1);
      expect(
        ClassroomProgressResolver.resolve(
          enrollment: nextUnit.enrollment!,
          unitIndex: 1,
        ).stage,
        ClassroomProgressStage.watchVideo,
      );
    },
  );

  test(
    'local course progress does not overwrite learner submission total',
    () async {
      final state = LearnerStateModel.fromFullJson('learner-a', {
        'submission_index': 3,
        'enrollment': {
          'course': 'course-1',
          'videos_completed': 1,
          'submission_index': 0,
          'quizzes_completed': 0,
        },
      });
      await cache.setForeverRaw(
        CacheKeys.learnerState('learner-a'),
        state.toJson(),
      );

      final restored = await repository.applyLocalProgress(
        learnerId: 'learner-a',
        submissionIndex: 1,
        xp: 20,
      );

      expect(restored.submissionIndex, 3);
      expect(restored.enrollment?.submissionIndex, 1);
    },
  );
}
