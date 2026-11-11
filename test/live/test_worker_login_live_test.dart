@Tags(['live'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:tapapp/core/cache/local_cache.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/constants/app_constants.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/auth/magic_link_repository.dart';
import 'package:tapapp/domain/progress/progress_repository.dart';

/// Signs in against the real test Worker with its seeded phones. It reads and
/// signs in only. It never writes progress or submissions.
///
/// Run it on purpose, with the Worker address:
///   flutter test test/live --tags live \
///     --dart-define=WORKER_URL=https://tapapp-test-worker.tapific.workers.dev
///
/// Without that address, every test here is skipped. `/test/mint-link` exists
/// only on the test Worker, and the app itself never calls it.
void main() {
  final onTestWorker = AppConstants.workerBaseUrl.contains(
    'tapapp-test-worker',
  );
  final skip = onTestWorker
      ? false
      : 'set --dart-define=WORKER_URL to the test Worker to run this';

  late Directory dir;
  late Box<String> values;
  late Box<String> indexes;
  late SecureTokenStore store;
  late MagicLinkRepository repo;
  late HttpClient http;
  final plain = Dio(BaseOptions(baseUrl: AppConstants.workerBaseUrl));

  setUp(() async {
    if (!onTestWorker) return;
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tap_live_');
    Hive.init(dir.path);
    values = await Hive.openBox<String>('values');
    indexes = await Hive.openBox<String>('indexes');
    store = SecureTokenStore(const FlutterSecureStorage());
    http = HttpClient(store);
    repo = MagicLinkRepository(
      http,
      LocalCache.forTesting(values, indexes),
      store,
    );
  });

  tearDown(() async {
    if (!onTestWorker) return;
    await values.close();
    await indexes.close();
    await dir.delete(recursive: true);
  });

  Future<String> mint(String phone) async {
    final r = await plain.post<Map>('/test/mint-link', data: {'phone': phone});
    return r.data!['data']['code'] as String;
  }

  test('fresh phone: one student, goes straight in', () async {
    final result = await repo.redeem(await mint('919100000001'));
    expect(result.needsPicker, isFalse);
    expect(result.activeStudent.studentId, 'STU-FRESH-01');

    // The saved student token works on a student route.
    final profile = await http.postApi('/profile/get_profile');
    expect(profile['student_id'], 'STU-FRESH-01');
  }, skip: skip);

  test('siblings phone: three students, the picker switches token', () async {
    final result = await repo.redeem(await mint('919100000004'));
    expect(result.needsPicker, isTrue);
    expect(result.students, hasLength(3));

    await repo.switchStudent('STU-SIB-02');
    final profile = await http.postApi('/profile/get_profile');
    expect(profile['student_id'], 'STU-SIB-02');
  }, skip: skip);

  test('a lost student token comes back through select_profile', () async {
    await repo.redeem(await mint('919100000004'));
    await store.forgetStudentToken('STU-SIB-03');

    await repo.switchStudent('STU-SIB-03');
    final profile = await http.postApi('/profile/get_profile');
    expect(profile['student_id'], 'STU-SIB-03');
  }, skip: skip);

  test('a phone with no enrollment: no code can be made for it', () async {
    await expectLater(
      mint('919100000006'),
      throwsA(isA<DioException>()),
      reason: 'the test Worker answers STUDENT_NOT_FOUND',
    );
  }, skip: skip);

  test('a bad code is refused with a Worker code, not a crash', () async {
    await expectLater(
      repo.redeem('AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-GGGG-HHHH-IIII-J'),
      throwsA(isA<ApiException>()),
    );
    expect(await store.readToken(), isNull);
  }, skip: skip);

  // Read-only progress calls. The writes (submit_video, submit_quiz) are not
  // run here: the test Worker's data is shared, and each write adds points.
  test('progress reads work with the saved student token', () async {
    await repo.redeem(await mint('919100000001'));
    final progress = ProgressRepository(http);

    final profile = await progress.getProfile();
    expect(profile.studentId, 'STU-FRESH-01');
    expect(profile.name, isNotEmpty);

    final sync = await progress.sync(lastUpdated: 0);
    expect(sync.changed, isTrue);
    expect(sync.points, isNotNull);
    expect(sync.currentLearningUnit, isNotNull);

    final last = await progress.lastSubmission(lastUpdated: 0);
    expect(last.points, isNotNull);

    final config = await progress.appConfig();
    expect(config.uploadMaxBytesVideo, greaterThan(config.uploadMaxBytesImage));
    expect(config.tierFor(0), 'bronze');
    expect(config.tierFor(1000), 'silver');
  }, skip: skip);
}
