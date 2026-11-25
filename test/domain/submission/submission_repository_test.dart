import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/progress/progress_models.dart';
import 'package:tapapp/domain/submission/submission_repository.dart';

import '../../support/fake_worker.dart';

Map<String, dynamic> _slot({int attempt = 1, int left = 1}) => {
  'upload_url': 'https://storage.example/up/obj.webp?sig=1',
  'object_key': 'tapapp/AS-1/S1/k-1.webp',
  'content_type': 'image/webp',
  'upload_headers': {
    'content-type': 'image/webp',
    'x-goog-content-length-range': '1,10485760',
  },
  'expires_in': 3600,
  'max_size_bytes': 10485760,
  'attempt_number': attempt,
  'attempts_remaining': left,
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  SubmissionRepository repoFor(
    FakeWorkerAdapter worker, {
    FakeWorkerAdapter? storage,
  }) {
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = worker,
    );
    final uploader = Dio()..httpClientAdapter = storage ?? worker;
    return SubmissionRepository(
      http,
      uploader: uploader,
      retryDelay: Duration.zero,
    );
  }

  group('requestUpload', () {
    test('asks for a slot for the assignment and the file type', () async {
      final adapter = FakeWorkerAdapter((_) => ok(_slot()));
      final slot = await repoFor(
        adapter,
      ).requestUpload(assignmentId: 'AS-1', type: SubmissionType.image);

      expect(adapter.seen.single.path, '/submission/request_upload');
      expect(adapter.seen.single.body, {
        'assignment_id': 'AS-1',
        'submission_type': 'image',
      });
      expect(slot.objectKey, 'tapapp/AS-1/S1/k-1.webp');
      expect(slot.maxSizeBytes, 10485760);
      expect(slot.attemptNumber, 1);
      expect(slot.attemptsRemaining, 1);
      expect(slot.headers['content-type'], 'image/webp');
    });

    test('a video asks for submission_type video', () async {
      final adapter = FakeWorkerAdapter((_) => ok(_slot()));
      await repoFor(
        adapter,
      ).requestUpload(assignmentId: 'AS-1', type: SubmissionType.video);
      expect(adapter.seen.single.body!['submission_type'], 'video');
    });

    test('the attempt cap is CONFLICT', () async {
      final adapter = FakeWorkerAdapter(
        (_) => failure(409, 'CONFLICT', 'cap reached'),
      );
      await expectLater(
        repoFor(
          adapter,
        ).requestUpload(assignmentId: 'AS-1', type: SubmissionType.image),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CONFLICT')),
      );
    });
  });

  group('upload', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    test(
      'tells how much was sent, from 0 to 1 (the "Sending… 60%" line)',
      () async {
        final worker = FakeWorkerAdapter((_) => ok(_slot()));
        final storage = _ProgressAdapter((_) => (status: 200, body: ''));
        final repo = repoFor(worker, storage: storage);
        final slot = await repo.requestUpload(
          assignmentId: 'AS-1',
          type: SubmissionType.image,
        );
        final seen = <double>[];

        await repo.upload(slot, bytes, onProgress: seen.add);

        expect(seen, [0.5, 1.0]);
      },
    );

    test('PUTs the bytes to the signed URL with the Worker headers', () async {
      final worker = FakeWorkerAdapter((_) => ok(_slot()));
      final storage = FakeWorkerAdapter((_) => (status: 200, body: ''));
      final repo = repoFor(worker, storage: storage);
      final slot = await repo.requestUpload(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
      );

      await repo.upload(slot, bytes);

      final put = storage.seen.single;
      expect(put.method, 'PUT');
      expect(put.path, 'https://storage.example/up/obj.webp?sig=1');
      expect(put.headers['content-type'], contains('image/webp'));
      expect(put.headers['x-goog-content-length-range'], '1,10485760');
      expect(
        put.headers.containsKey('Authorization'),
        isFalse,
        reason: 'the signed URL must not get our token',
      );
      expect(put.raw, bytes);
    });

    test(
      'with the skip switch on, nothing is PUT (test Worker only)',
      () async {
        final worker = FakeWorkerAdapter((_) => ok(_slot()));
        final storage = FakeWorkerAdapter((_) => (status: 500, body: ''));
        final http = HttpClient(
          SecureTokenStore(const FlutterSecureStorage()),
          dio: Dio()..httpClientAdapter = worker,
        );
        final repo = SubmissionRepository(
          http,
          uploader: Dio()..httpClientAdapter = storage,
          retryDelay: Duration.zero,
          skipUpload: true,
        );
        final slot = await repo.requestUpload(
          assignmentId: 'AS-1',
          type: SubmissionType.image,
        );

        await repo.upload(slot, bytes);

        expect(storage.seen, isEmpty);
      },
    );

    test('a file over the limit is refused before any request', () async {
      final worker = FakeWorkerAdapter((_) => ok(_slot()));
      final storage = FakeWorkerAdapter((_) => (status: 200, body: ''));
      final repo = repoFor(worker, storage: storage);
      final slot = await repo.requestUpload(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
      );

      await expectLater(
        repo.upload(slot, Uint8List(slot.maxSizeBytes + 1)),
        throwsA(isA<FileTooBigException>()),
      );
      expect(storage.seen, isEmpty);
    });

    test('a failed upload is tried again, then works', () async {
      final worker = FakeWorkerAdapter((_) => ok(_slot()));
      var calls = 0;
      final storage = FakeWorkerAdapter((_) {
        calls++;
        return calls < 3 ? (status: 503, body: '') : (status: 200, body: '');
      });
      final repo = repoFor(worker, storage: storage);
      final slot = await repo.requestUpload(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
      );

      await repo.upload(slot, bytes);
      expect(storage.seen, hasLength(3));
    });

    test('after 3 failures it gives up with an error', () async {
      final worker = FakeWorkerAdapter((_) => ok(_slot()));
      final storage = FakeWorkerAdapter((_) => (status: 503, body: ''));
      final repo = repoFor(worker, storage: storage);
      final slot = await repo.requestUpload(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
      );

      await expectLater(
        repo.upload(slot, bytes),
        throwsA(isA<UploadFailedException>()),
      );
      expect(storage.seen, hasLength(3));
    });
  });

  group('submitArtwork', () {
    Map<String, dynamic> accepted({String idKey = 'submission_id'}) => {
      idKey: 'SUB-9',
      'status': 'Pending',
      'assignment_id_link': 'AS-1',
      'attempt_number': 1,
      'attempts_remaining': 1,
      'points_awarded': 25,
      'points_total': 325,
      'updated_at': 5,
      'repeat': false,
    };

    test(
      'sends the assignment, the object key and the idempotency key',
      () async {
        final adapter = FakeWorkerAdapter((_) => ok(accepted()));
        final result = await repoFor(adapter).submitArtwork(
          assignmentId: 'AS-1',
          objectKey: 'tapapp/AS-1/S1/k-1.webp',
          idempotencyKey: 'artwork:S1:AS-1:abc',
        );

        expect(adapter.seen.single.path, '/submission/submit_artwork');
        expect(adapter.seen.single.body, {
          'assignment_id': 'AS-1',
          'object_key': 'tapapp/AS-1/S1/k-1.webp',
          'idempotency_key': 'artwork:S1:AS-1:abc',
        });
        expect(result.submissionId, 'SUB-9');
        expect(result.isPending, isTrue);
        expect(result.pointsAwarded, 25);
        expect(result.pointsTotal, 325);
        expect(result.attemptsRemaining, 1);
      },
    );

    // shortcut: the test Worker still says "name". Remove when it says submission_id.
    test(
      'reads the id from "name" while the test Worker still sends that',
      () async {
        final adapter = FakeWorkerAdapter((_) => ok(accepted(idKey: 'name')));
        final result = await repoFor(adapter).submitArtwork(
          assignmentId: 'AS-1',
          objectKey: 'k',
          idempotencyKey: 'x',
        );
        expect(result.submissionId, 'SUB-9');
      },
    );

    test(
      'the Worker errors on a failed upload are thrown with their code',
      () async {
        for (final code in [
          'upload_not_confirmed',
          'upload_size_invalid',
          'upload_type_mismatch',
        ]) {
          final adapter = FakeWorkerAdapter((_) => failure(400, code, 'm'));
          await expectLater(
            repoFor(adapter).submitArtwork(
              assignmentId: 'AS-1',
              objectKey: 'k',
              idempotencyKey: 'x',
            ),
            throwsA(isA<ApiException>().having((e) => e.code, 'code', code)),
          );
        }
      },
    );
  });

  group('list and get', () {
    Map<String, dynamic> row(String id, String result, int? score) => {
      'submission_id': id,
      'assignment_id_link': 'AS-1',
      'status': result == 'Pending' ? 'Pending' : 'Completed',
      'result_status': result,
      'score': score,
      'attempt_number': 1,
      'attempts_remaining': 1,
    };

    test('list reads every row', () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok({
          'submissions': [
            row('SUB-1', 'Success - Original', 78),
            row('SUB-2', 'Pending', null),
          ],
          'count': 2,
        }),
      );
      final rows = await repoFor(adapter).list();
      expect(adapter.seen.single.path, '/submission/list');
      expect(rows.map((r) => r.id), ['SUB-1', 'SUB-2']);
      expect(rows.first.assignmentId, 'AS-1');
    });

    test('latest picks the newest attempt for the assignment', () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok({
          'submissions': [
            {...row('SUB-1', 'Failed', 10), 'attempt_number': 1},
            {...row('SUB-2', 'Pending', null), 'attempt_number': 2},
            {
              ...row('SUB-3', 'Success - Original', 90),
              'assignment_id_link': 'AS-OTHER',
              'attempt_number': 9,
            },
          ],
        }),
      );
      final latest = await repoFor(adapter).latest('AS-1');
      expect(latest?.id, 'SUB-2');
    });

    test('latest is null when nothing was sent', () async {
      final adapter = FakeWorkerAdapter((_) => ok({'submissions': []}));
      expect(await repoFor(adapter).latest('AS-1'), isNull);
    });

    test('get asks for one submission', () async {
      final adapter = FakeWorkerAdapter(
        (_) => ok(row('SUB-1', 'Success - Original', 78)),
      );
      final one = await repoFor(adapter).get('SUB-1');
      expect(adapter.seen.single.path, '/submission/get');
      expect(adapter.seen.single.body, {'submission_id': 'SUB-1'});
      expect(one.id, 'SUB-1');
    });
  });

  group('valid or not (API contract section 4)', () {
    SubmissionInfo withResult(String? result, int? score) => SubmissionInfo(
      id: 'S',
      status: 'Completed',
      resultStatus: result,
      score: score,
    );

    test('only "Success - Original" with a score above 0 is valid', () {
      expect(withResult('Success - Original', 78).isValid, isTrue);
      expect(withResult('Success - Original', 1).isValid, isTrue);
    });

    test('score 0 is not valid (the AI could not judge the work)', () {
      expect(withResult('Success - Original', 0).isValid, isFalse);
    });

    test('flagged, failed, pending and unknown values are not valid', () {
      for (final r in [
        'Success - Flagged',
        'Failed',
        'Pending',
        'Needs Retry',
        '',
        null,
      ]) {
        expect(withResult(r, 90).isValid, isFalse, reason: '$r');
      }
    });

    test('a missing score on an original result is not valid', () {
      expect(withResult('Success - Original', null).isValid, isFalse);
    });

    test('the status text is read without case', () {
      expect(withResult('success - original', 50).isValid, isTrue);
    });
  });
}

/// A storage that reports 2 of 4 bytes, then 4 of 4, as the real upload does.
class _ProgressAdapter extends FakeWorkerAdapter {
  _ProgressAdapter(super.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    options.onSendProgress?.call(2, 4);
    options.onSendProgress?.call(4, 4);
    return super.fetch(options, requestStream, cancelFuture);
  }
}
