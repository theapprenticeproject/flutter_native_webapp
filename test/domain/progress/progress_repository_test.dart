import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/progress/idempotency_key.dart';
import 'package:tapapp/domain/progress/progress_repository.dart';

import '../../support/fake_worker.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ProgressRepository repoFor(FakeWorkerAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    return ProgressRepository(
      HttpClient(SecureTokenStore(const FlutterSecureStorage()), dio: dio),
    );
  }

  group('video', () {
    Map<String, dynamic> awarded({bool repeat = false}) => {
      'points_awarded': 10,
      'points_total': 337,
      'points_tier': 'bronze',
      'context': 'program',
      'updated_at': 1794026773,
      'repeat': repeat,
    };

    test('sends the unit, the video, watched and the key', () async {
      final adapter = FakeWorkerAdapter((_) => ok(awarded()));
      final result = await repoFor(adapter).submitVideo(
        unitId: 'LU-0088',
        videoId: 'VC-1',
        watched: true,
        idempotencyKey: 'video:S1:VC-1:abc',
      );

      final call = adapter.seen.single;
      expect(call.path, '/progress/submit_video_watched');
      expect(call.body, {
        'unit_id': 'LU-0088',
        'video_id': 'VC-1',
        'watched': true,
        'idempotency_key': 'video:S1:VC-1:abc',
      });
      expect(result.pointsAwarded, 10);
      expect(result.pointsTotal, 337);
      expect(result.pointsTier, 'bronze');
      expect(result.isRepeat, isFalse);
    });

    test('a repeat of the same key is reported, not an error', () async {
      final adapter = FakeWorkerAdapter((_) => ok(awarded(repeat: true)));
      final result = await repoFor(adapter).submitVideo(
        unitId: 'U',
        videoId: 'V',
        watched: true,
        idempotencyKey: 'k',
      );
      expect(result.isRepeat, isTrue);
    });

    test('the video cap throws CONFLICT', () async {
      final adapter = FakeWorkerAdapter(
        (_) => failure(409, 'CONFLICT', 'per-unit video-event cap reached'),
      );
      await expectLater(
        repoFor(adapter).submitVideo(
          unitId: 'U',
          videoId: 'V',
          watched: true,
          idempotencyKey: 'k',
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CONFLICT')),
      );
    });

    // TEMPORARY: the test Worker still has only the old route name. Remove this
    // test and the fallback in ProgressRepository once it has the new one.
    test(
      'falls back to the old route while the Worker lacks the new one',
      () async {
        final adapter = FakeWorkerAdapter((r) {
          if (r.path == '/progress/submit_video_watched') {
            return failure(404, 'NOT_FOUND', 'no such route');
          }
          return ok(awarded());
        });
        final result = await repoFor(adapter).submitVideo(
          unitId: 'U',
          videoId: 'V',
          watched: true,
          idempotencyKey: 'k',
        );
        expect(adapter.seen.map((r) => r.path), [
          '/progress/submit_video_watched',
          '/progress/submit_video',
        ]);
        expect(adapter.seen.last.body!['idempotency_key'], 'k');
        expect(result.pointsAwarded, 10);
      },
    );

    test('a real NOT_FOUND (not a missing route) is not retried', () async {
      final adapter = FakeWorkerAdapter(
        (_) => failure(404, 'NOT_FOUND', 'video does not exist'),
      );
      await expectLater(
        repoFor(adapter).submitVideo(
          unitId: 'U',
          videoId: 'V',
          watched: true,
          idempotencyKey: 'k',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.seen, hasLength(1));
    });
  });

  group('quiz', () {
    test('sends the answers in order and reads the score', () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok({
          'correct_count': 2,
          'total_count': 3,
          'points_awarded': 2,
          'points_total': 327,
          'points_tier': 'bronze',
          'updated_at': 5,
          'repeat': false,
        }),
      );
      final result = await repoFor(adapter).submitQuiz(
        unitId: 'LU-0088',
        quizId: 'QZ-1',
        answers: const [
          QuizAnswer(questionId: 'Q1', selectedKey: 'a'),
          QuizAnswer(questionId: 'Q2', selectedKey: 'c'),
          QuizAnswer(questionId: 'Q3', selectedKey: 'a'),
        ],
        idempotencyKey: 'quiz:S1:LU-0088:z',
      );

      expect(adapter.seen.single.path, '/progress/submit_quiz');
      expect(adapter.seen.single.body!['quiz_id'], 'QZ-1');
      expect(adapter.seen.single.body!['answers'], [
        {'question_id': 'Q1', 'selected_key': 'a'},
        {'question_id': 'Q2', 'selected_key': 'c'},
        {'question_id': 'Q3', 'selected_key': 'a'},
      ]);
      expect(result.correctCount, 2);
      expect(result.totalCount, 3);
      expect(result.pointsAwarded, 2);
    });

    test('an empty answer list is refused before any request', () async {
      final adapter = FakeWorkerAdapter((_) => ok({}));
      await expectLater(
        repoFor(adapter).submitQuiz(
          unitId: 'U',
          quizId: 'Z',
          answers: const [],
          idempotencyKey: 'k',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(adapter.seen, isEmpty);
    });
  });

  group('sync', () {
    test('nothing changed', () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok({'changed': false, 'updated_at': 1794026909}),
      );
      final result = await repoFor(adapter).sync(lastUpdated: 1794026000);
      expect(adapter.seen.single.body, {'last_updated': 1794026000});
      expect(result.changed, isFalse);
      expect(result.updatedAt, 1794026909);
      expect(result.points, isNull);
    });

    test(
      'something changed, with the resume state and extra fields ignored',
      () async {
        final adapter = FakeWorkerAdapter(
          (_) => ok({
            'changed': true,
            'updated_at': 1794026909,
            'points': 337,
            'points_tier': 'bronze',
            'gems': 50,
            'current_learning_unit': 'LU-0088',
            'last_activity_type': 'video',
          }),
        );
        final result = await repoFor(adapter).sync(lastUpdated: 1);
        expect(result.changed, isTrue);
        expect(result.points, 337);
        expect(result.currentLearningUnit, 'LU-0088');
        expect(result.lastActivityType, 'video');
        expect(result.lastSubmission, isNull);
      },
    );

    test('a graded submission comes with it; status ignores case', () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok({
          'changed': true,
          'updated_at': 9,
          'points': 1,
          'last_submission': {
            'name': 'SUB-1',
            'status': 'Completed',
            'result_status': 'Success - Original',
            'view_url': 'https://x/y.webp',
            'score': 78,
            'overall_feedback_translated': 'Well done',
            'overall_feedback_audio_url': null,
            'attempt_number': 1,
            'attempts_remaining': 1,
            'updated_at': 9,
          },
        }),
      );
      final sub = (await repoFor(adapter).sync(lastUpdated: 1)).lastSubmission!;
      expect(sub.id, 'SUB-1');
      expect(sub.isGraded, isTrue);
      expect(sub.isPending, isFalse);
      expect(sub.score, 78);
      expect(sub.attemptsRemaining, 1);
      expect(sub.canSendAgain, isTrue);
    });

    test('pending and lower-case statuses are read the same way', () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok({
          'changed': true,
          'updated_at': 9,
          'last_submission': {
            'name': 'SUB-2',
            'status': 'pending',
            'attempt_number': 2,
            'attempts_remaining': 0,
          },
        }),
      );
      final sub = (await repoFor(adapter).sync(lastUpdated: 1)).lastSubmission!;
      expect(sub.isPending, isTrue);
      expect(sub.isGraded, isFalse);
      expect(sub.canSendAgain, isFalse);
    });
  });

  test('profile and config', () async {
    final adapter = FakeWorkerAdapter((r) {
      if (r.path == '/profile/get_profile') {
        return ok({
          'student_id': 'S1',
          'name1': 'Asha New',
          'language': 'en',
          'grade': '5',
          'course_id': 'CRS-SCI-05',
        });
      }
      return ok({
        'upload_max_bytes_image': 10485760,
        'upload_max_bytes_video': 52428800,
        'point_tiers': [
          {'id': 'bronze', 'min': 0},
          {'id': 'silver', 'min': 1000},
        ],
      });
    });
    final repo = repoFor(adapter);

    final profile = await repo.getProfile();
    expect(profile.name, 'Asha New');
    expect(profile.courseId, 'CRS-SCI-05');

    final config = await repo.appConfig();
    expect(adapter.seen.last.method, 'GET');
    expect(config.uploadMaxBytesVideo, 52428800);
    expect(config.tierFor(999), 'bronze');
    expect(config.tierFor(1000), 'silver');
  });

  group('idempotency keys', () {
    test('are unique per call and say what they are for', () {
      final a = newIdempotencyKey('video', 'S1', 'LU-1');
      final b = newIdempotencyKey('video', 'S1', 'LU-1');
      expect(a, isNot(b));
      expect(a, startsWith('video:S1:LU-1:'));
      expect(a.length, lessThan(100));
    });
  });
}
