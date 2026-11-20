import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:tapapp/core/cache/cache_keys.dart';
import 'package:tapapp/core/cache/local_cache.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/learner/learner_state_provider.dart';
import 'package:tapapp/domain/learner/learner_state_repository.dart';
import 'package:tapapp/domain/program_content/course_detail_model.dart';
import 'package:tapapp/domain/progress/progress_repository.dart';

import '../../support/fake_worker.dart';

/// A student opens the app in a NEW browser: nothing is saved. The app must ask
/// the Worker (`/progress/sync`) where the student is. It used to skip that on
/// the first load, so the unit and the steps the Worker has were never read, and
/// the student saw "Start Activity" again.
void main() {
  late Directory dir;
  late Box<String> values;
  late Box<String> indexes;
  late LocalCache cache;
  late FakeWorkerAdapter worker;
  late LearnerStateRepository repo;

  final units = [
    for (final n in [1, 2])
      CourseUnitModel(
        unitId: 'U-$n',
        name: 'Unit $n',
        description: '',
        requiredComponents: '',
        difficulty: '',
        xp: 0,
        videos: const [],
        assignments: const [],
      ),
  ];

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tap_first_load_');
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
    worker = FakeWorkerAdapter(
      (_) => ok({
        'changed': true,
        'updated_at': 9,
        'points': 10,
        'current_learning_unit': 'U-2',
        'last_activity_type': 'video',
      }),
    );
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = worker,
    );
    repo = LearnerStateRepository(
      http,
      cache,
      progress: ProgressRepository(http),
      resolveCourse: (id) async => id,
    );
  });

  tearDown(() async {
    await values.close();
    await indexes.close();
    await dir.delete(recursive: true);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        learnerStateRepositoryProvider.overrideWith((ref) async => repo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('the first load in a new browser asks the Worker (sync)', () async {
    final state = await container().read(learnerStateDataProvider('S1').future);

    expect(worker.seen.map((r) => r.path), contains('/progress/sync'));
    expect(state.xp, 10, reason: 'the Worker\'s points, not the login\'s');
  });

  test(
    'what sync said is then used to put the student on the Worker\'s unit',
    () async {
      await container().read(learnerStateDataProvider('S1').future);

      final state = await repo.alignToWorkerUnit('S1', units);

      // Unit 2, video done (last activity: video).
      expect(state.enrollment!.videosCompleted, 2);
      expect(state.enrollment!.quizzesCompleted, 1);
    },
  );

  test('a later load of the same browser still asks the Worker once', () async {
    final c = container();
    await c.read(learnerStateDataProvider('S1').future);
    c.invalidate(learnerStateDataProvider('S1'));
    await c.read(learnerStateDataProvider('S1').future);
    expect(worker.seen.where((r) => r.path == '/progress/sync'), hasLength(2));
  });
}
