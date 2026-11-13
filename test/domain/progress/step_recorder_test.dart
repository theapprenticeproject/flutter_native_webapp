import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/progress/progress_repository.dart';
import 'package:tapapp/domain/progress/step_recorder.dart';

import '../../support/fake_worker.dart';

Map<String, dynamic> _awarded({bool repeat = false}) => {
  'points_awarded': repeat ? 10 : 10,
  'points_total': 310,
  'points_tier': 'bronze',
  'updated_at': 1,
  'repeat': repeat,
};

void main() {
  quizTests();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  StepRecorder recorderFor(FakeWorkerAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: dio,
    );
    return StepRecorder(ProgressRepository(http), studentId: 'S1');
  }

  test('records the video and returns the points the Worker gave', () async {
    final adapter = FakeWorkerAdapter((_) => ok(_awarded()));
    final record = await recorderFor(
      adapter,
    ).recordVideo(unitId: 'U1', videoId: 'V1');

    expect(record.pointsAwarded, 10);
    expect(record.pointsTotal, 310);
    expect(record.alreadyRecorded, isFalse);
    expect(adapter.seen.single.body!['unit_id'], 'U1');
    expect(adapter.seen.single.body!['video_id'], 'V1');
    expect(adapter.seen.single.body!['watched'], true);
  });

  test('a retry after a network failure sends the SAME key', () async {
    var calls = 0;
    final adapter = FakeWorkerAdapter((_) {
      calls++;
      return calls == 1 ? (status: 502, body: 'bad gateway') : ok(_awarded());
    });
    final recorder = recorderFor(adapter);

    await expectLater(
      recorder.recordVideo(unitId: 'U1', videoId: 'V1'),
      throwsA(anything),
    );
    await recorder.recordVideo(unitId: 'U1', videoId: 'V1');

    final keys = adapter.seen.map((r) => r.body!['idempotency_key']).toList();
    expect(keys, hasLength(2));
    expect(keys[0], keys[1], reason: 'the key must be kept until it works');
  });

  test(
    'a repeat answer keeps the original points (our retry succeeded)',
    () async {
      final adapter = FakeWorkerAdapter((_) => ok(_awarded(repeat: true)));
      final record = await recorderFor(
        adapter,
      ).recordVideo(unitId: 'U1', videoId: 'V1');
      expect(record.alreadyRecorded, isTrue);
      expect(
        record.pointsAwarded,
        10,
        reason: 'the first request earned them, the answer was lost',
      );
    },
  );

  test(
    'CONFLICT means the video was marked before: go on, no points',
    () async {
      final adapter = FakeWorkerAdapter(
        (_) => failure(409, 'CONFLICT', 'cap reached'),
      );
      final record = await recorderFor(
        adapter,
      ).recordVideo(unitId: 'U1', videoId: 'V1');
      expect(record.alreadyRecorded, isTrue);
      expect(record.pointsAwarded, 0);
      expect(record.pointsTotal, isNull);
    },
  );

  test('other Worker errors are thrown so the Retry button shows', () async {
    final adapter = FakeWorkerAdapter(
      (_) => failure(502, 'UPSTREAM_ERROR', 'down'),
    );
    await expectLater(
      recorderFor(adapter).recordVideo(unitId: 'U1', videoId: 'V1'),
      throwsA(anything),
    );
  });

  test('a different video gets a different key', () async {
    final adapter = FakeWorkerAdapter((_) => ok(_awarded()));
    final recorder = recorderFor(adapter);
    await recorder.recordVideo(unitId: 'U1', videoId: 'V1');
    await recorder.recordVideo(unitId: 'U2', videoId: 'V2');
    expect(
      adapter.seen[0].body!['idempotency_key'],
      isNot(adapter.seen[1].body!['idempotency_key']),
    );
  });

  test('once recorded, asking again does not call the Worker again', () async {
    final adapter = FakeWorkerAdapter((_) => ok(_awarded()));
    final recorder = recorderFor(adapter);
    await recorder.recordVideo(unitId: 'U1', videoId: 'V1');
    final again = await recorder.recordVideo(unitId: 'U1', videoId: 'V1');
    expect(adapter.seen, hasLength(1));
    expect(again.pointsAwarded, 10);
  });
}

// ---- Quiz ----

const _answers = [
  QuizAnswer(questionId: 'Q1', selectedKey: 'b'),
  QuizAnswer(questionId: 'Q2', selectedKey: 'a'),
];

Map<String, dynamic> _scored({bool repeat = false}) => {
  'correct_count': 1,
  'total_count': 2,
  'points_awarded': 1,
  'points_total': 301,
  'points_tier': 'bronze',
  'updated_at': 2,
  'repeat': repeat,
};

void quizTests() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  StepRecorder recorderFor(FakeWorkerAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: dio,
    );
    return StepRecorder(ProgressRepository(http), studentId: 'S1');
  }

  group('quiz', () {
    test('sends the answers once and returns the Worker points', () async {
      final adapter = FakeWorkerAdapter((_) => ok(_scored()));
      final record = await recorderFor(
        adapter,
      ).recordQuiz(unitId: 'U1', quizId: 'Z1', answers: _answers);

      final body = adapter.seen.single.body!;
      expect(adapter.seen.single.path, '/progress/submit_quiz');
      expect(body['unit_id'], 'U1');
      expect(body['quiz_id'], 'Z1');
      expect(body['answers'], [
        {'question_id': 'Q1', 'selected_key': 'b'},
        {'question_id': 'Q2', 'selected_key': 'a'},
      ]);
      expect(record.pointsAwarded, 1, reason: 'the Worker gives +1 for each');
      expect(record.pointsTotal, 301);
      expect(record.alreadyRecorded, isFalse);
    });

    test('a retry after a network failure sends the SAME key', () async {
      var calls = 0;
      final adapter = FakeWorkerAdapter((_) {
        calls++;
        return calls == 1 ? (status: 502, body: 'bad') : ok(_scored());
      });
      final recorder = recorderFor(adapter);
      await expectLater(
        recorder.recordQuiz(unitId: 'U1', quizId: 'Z1', answers: _answers),
        throwsA(anything),
      );
      await recorder.recordQuiz(unitId: 'U1', quizId: 'Z1', answers: _answers);
      final keys = adapter.seen.map((r) => r.body!['idempotency_key']).toList();
      expect(keys[0], keys[1]);
    });

    test('CONFLICT means already scored: go on with no points', () async {
      final adapter = FakeWorkerAdapter(
        (_) => failure(409, 'CONFLICT', 'quiz cap reached'),
      );
      final record = await recorderFor(
        adapter,
      ).recordQuiz(unitId: 'U1', quizId: 'Z1', answers: _answers);
      expect(record.alreadyRecorded, isTrue);
      expect(record.pointsAwarded, 0);
      expect(record.pointsTotal, isNull);
    });

    test('only the first scored attempt is sent (a retake is not)', () async {
      final adapter = FakeWorkerAdapter((_) => ok(_scored()));
      final recorder = recorderFor(adapter);
      await recorder.recordQuiz(unitId: 'U1', quizId: 'Z1', answers: _answers);
      final retake = await recorder.recordQuiz(
        unitId: 'U1',
        quizId: 'Z1',
        answers: const [QuizAnswer(questionId: 'Q1', selectedKey: 'c')],
      );
      expect(adapter.seen, hasLength(1));
      expect(retake.pointsAwarded, 1, reason: 'the first result stays');
    });

    test('other Worker errors are thrown so the Retry button shows', () async {
      final adapter = FakeWorkerAdapter(
        (_) => failure(502, 'UPSTREAM_ERROR', 'down'),
      );
      await expectLater(
        recorderFor(
          adapter,
        ).recordQuiz(unitId: 'U1', quizId: 'Z1', answers: _answers),
        throwsA(anything),
      );
    });
  });
}
