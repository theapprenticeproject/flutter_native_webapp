import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:tapapp/core/cache/cache_keys.dart';
import 'package:tapapp/core/cache/local_cache.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/auth/magic_link_repository.dart';

import '../../support/fake_worker.dart';

Map<String, dynamic> student(String id, String name, String grade) => {
  'student_id': id,
  'token': 'tok-$id',
  'name': name,
  'grade': grade,
  'points': 300,
  'points_tier': 'bronze',
  'current_learning_unit': 'LU-0088',
  'course_id': 'CRS-SCI-05',
  'language': 'en',
};

void main() {
  late Directory dir;
  late Box<String> values;
  late Box<String> indexes;
  late LocalCache cache;
  late SecureTokenStore store;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tap_magic_link_');
    Hive.init(dir.path);
    values = await Hive.openBox<String>('values');
    indexes = await Hive.openBox<String>('indexes');
    cache = LocalCache.forTesting(values, indexes);
    store = SecureTokenStore(const FlutterSecureStorage());
  });

  tearDown(() async {
    await values.close();
    await indexes.close();
    await dir.delete(recursive: true);
  });

  MagicLinkRepository repoFor(FakeWorkerAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    return MagicLinkRepository(HttpClient(store, dio: dio), cache, store);
  }

  test(
    'one student: stores the token and says there is nothing to pick',
    () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok({
          'phone_token': 'phone-tok',
          'active_student_id': 'S1',
          'students': [student('S1', 'Asha', '5')],
        }),
      );
      final repo = repoFor(adapter);

      final result = await repo.redeem('  AEAA-AAGX-72SS  ');

      expect(adapter.seen.single.path, '/auth/redeem');
      expect(adapter.seen.single.body, {'code': 'AEAA-AAGX-72SS'});
      expect(result.needsPicker, isFalse);
      expect(result.activeStudent.name, 'Asha');
      expect(await store.readToken(), 'tok-S1');
      expect(await store.readPhoneToken(), 'phone-tok');
    },
  );

  test(
    'several students: needs the picker, no student is chosen yet',
    () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok({
          'phone_token': 'phone-tok',
          'active_student_id': 'S1',
          'students': [
            student('S1', 'Durva', '5'),
            student('S2', 'Manu', '8'),
            student('S3', 'Om', '3'),
          ],
        }),
      );
      final repo = repoFor(adapter);

      final result = await repo.redeem('CODE');

      expect(result.needsPicker, isTrue);
      expect(result.students.map((s) => s.name), ['Durva', 'Manu', 'Om']);
      final roster = await repo.readRoster();
      expect(roster.map((s) => s.studentId), ['S1', 'S2', 'S3']);
    },
  );

  test('several students: an old active profile is cleared', () async {
    await cache.setForeverRaw(CacheKeys.activeProfile(), {
      'phone': '',
      'learner_id': 'OLD',
      'student_name': 'Old',
      'onboarding_completed': true,
    });
    final adapter = FakeWorkerAdapter(
      (_) => ok({
        'phone_token': 'p',
        'active_student_id': 'S1',
        'students': [student('S1', 'Durva', '5'), student('S2', 'Manu', '8')],
      }),
    );

    await repoFor(adapter).redeem('CODE');

    expect(cache.has(CacheKeys.activeProfile()), isFalse);
  });

  test('one student: becomes the active profile, already onboarded', () async {
    final adapter = FakeWorkerAdapter(
      (_) => ok({
        'phone_token': 'p',
        'active_student_id': 'S1',
        'students': [student('S1', 'Asha', '5')],
      }),
    );

    await repoFor(adapter).redeem('CODE');

    final saved = cache.getForeverRaw(CacheKeys.activeProfile())!;
    expect(saved['learner_id'], 'S1');
    expect(saved['onboarding_completed'], true);
  });

  test('switching student changes the token with no network call', () async {
    final adapter = FakeWorkerAdapter(
      (_) => ok({
        'phone_token': 'phone-tok',
        'active_student_id': 'S1',
        'students': [student('S1', 'Durva', '5'), student('S2', 'Manu', '8')],
      }),
    );
    final repo = repoFor(adapter);
    await repo.redeem('CODE');
    final calls = adapter.seen.length;

    final chosen = await repo.switchStudent('S2');

    expect(chosen.name, 'Manu');
    expect(await store.readToken(), 'tok-S2');
    expect(adapter.seen.length, calls, reason: 'no request needed');
  });

  test('a lost student token is fetched again with the phone token', () async {
    final adapter = FakeWorkerAdapter((r) {
      if (r.path == '/auth/redeem') {
        return ok({
          'phone_token': 'phone-tok',
          'active_student_id': 'S1',
          'students': [student('S1', 'Durva', '5'), student('S2', 'Manu', '8')],
        });
      }
      return ok({...student('S2', 'Manu', '8'), 'token': 'fresh-S2'});
    });
    final repo = repoFor(adapter);
    await repo.redeem('CODE');
    await store.forgetStudentToken('S2');

    await repo.switchStudent('S2');

    final call = adapter.seen.last;
    expect(call.path, '/auth/select_profile');
    expect(call.body, {'student_id': 'S2'});
    expect(call.headers['Authorization'], 'Bearer phone-tok');
    expect(await store.readToken(), 'fresh-S2');
  });

  test('picking a student that is not on the phone is refused', () async {
    final adapter = FakeWorkerAdapter(
      (_) => ok({
        'phone_token': 'p',
        'active_student_id': 'S1',
        'students': [student('S1', 'Asha', '5')],
      }),
    );
    final repo = repoFor(adapter);
    await repo.redeem('CODE');

    await expectLater(repo.switchStudent('NOPE'), throwsA(isA<StateError>()));
  });

  test('a bad link throws the Worker code and stores nothing', () async {
    final adapter = FakeWorkerAdapter(
      (_) => failure(401, 'UNAUTHORIZED', "signature doesn't verify"),
    );
    final repo = repoFor(adapter);

    await expectLater(
      repo.redeem('CODE'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'UNAUTHORIZED'),
      ),
    );
    expect(await store.readToken(), isNull);
  });

  test('a phone with no student throws STUDENT_NOT_FOUND', () async {
    final adapter = FakeWorkerAdapter(
      (_) => failure(404, 'STUDENT_NOT_FOUND', 'no enrolled student'),
    );
    await expectLater(
      repoFor(adapter).redeem('CODE'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'STUDENT_NOT_FOUND'),
      ),
    );
  });

  test('an empty student list is treated as no student', () async {
    final adapter = FakeWorkerAdapter(
      (_) => ok({'phone_token': 'p', 'active_student_id': '', 'students': []}),
    );
    await expectLater(
      repoFor(adapter).redeem('CODE'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'STUDENT_NOT_FOUND'),
      ),
    );
  });

  test('the model never reads gems (v1 has none)', () async {
    final adapter = FakeWorkerAdapter(
      (_) => ok({
        'phone_token': 'p',
        'active_student_id': 'S1',
        'students': [
          {...student('S1', 'Asha', '5'), 'gems': 50},
        ],
      }),
    );
    final result = await repoFor(adapter).redeem('CODE');
    expect(result.activeStudent.toJson().keys, isNot(contains('gems')));
  });
}
