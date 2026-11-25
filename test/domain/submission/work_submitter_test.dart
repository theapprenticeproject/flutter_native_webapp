import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/cache/secure_token_store.dart';
import 'package:tapapp/core/network/api_exception.dart';
import 'package:tapapp/core/network/http_client.dart';
import 'package:tapapp/domain/submission/submission_repository.dart';
import 'package:tapapp/domain/submission/work_submitter.dart';

import '../../support/fake_worker.dart';

Map<String, dynamic> _slot({int max = 1000, String type = 'image/jpeg'}) => {
  'upload_url': 'https://storage.example/up?sig=1',
  'object_key': 'tapapp/AS-1/S1/k-1.jpg',
  'content_type': type,
  'upload_headers': {'content-type': type},
  'max_size_bytes': max,
  'attempt_number': 1,
  'attempts_remaining': 1,
};

Map<String, dynamic> _accepted() => {
  'submission_id': 'SUB-1',
  'status': 'Pending',
  'attempt_number': 1,
  'attempts_remaining': 1,
  'points_awarded': 25,
  'points_total': 325,
  'repeat': false,
};

/// A Worker and a storage that can be told to fail, and that count calls.
class _Rig {
  _Rig({int max = 1000}) : _max = max {
    worker = FakeWorkerAdapter((r) {
      calls.add(r.path);
      switch (r.path) {
        case '/submission/request_upload':
          return requestUploadReply ?? ok(_slot(max: _max));
        case '/submission/submit_artwork':
          keys.add(r.body!['idempotency_key'] as String);
          return submitReply ?? ok(_accepted());
      }
      return failure(404, 'NOT_FOUND', 'no such route');
    });
    storage = FakeWorkerAdapter((r) {
      calls.add('PUT');
      return uploadReply ?? (status: 200, body: '');
    });
  }

  final int _max;
  final calls = <String>[];
  final keys = <String>[];
  late final FakeWorkerAdapter worker;
  late final FakeWorkerAdapter storage;
  ({int status, Object body})? requestUploadReply;
  ({int status, Object body})? submitReply;
  ({int status, Object body})? uploadReply;

  WorkSubmitter submitter({
    Future<Uint8List> Function(Uint8List, String)? prepareImage,
  }) {
    FlutterSecureStorage.setMockInitialValues({});
    final http = HttpClient(
      SecureTokenStore(const FlutterSecureStorage()),
      dio: Dio()..httpClientAdapter = worker,
    );
    final repo = SubmissionRepository(
      http,
      uploader: Dio()..httpClientAdapter = storage,
      retryDelay: Duration.zero,
    );
    return WorkSubmitter(repo, studentId: 'S1', prepareImage: prepareImage);
  }
}

void main() {
  final photo = Uint8List.fromList([1, 2, 3]);

  test('runs the three calls in order and returns the Worker points', () async {
    final rig = _Rig();
    final result = await rig.submitter().submit(
      assignmentId: 'AS-1',
      type: SubmissionType.image,
      bytes: photo,
    );
    expect(rig.calls, [
      '/submission/request_upload',
      'PUT',
      '/submission/submit_artwork',
    ]);
    expect(result.pointsAwarded, 25);
    expect(result.pointsTotal, 325);
  });

  test('a photo is shrunk first, and the shrunk bytes are uploaded', () async {
    final rig = _Rig();
    final small = Uint8List.fromList([9]);
    await rig
        .submitter(prepareImage: (_, _) async => small)
        .submit(assignmentId: 'AS-1', type: SubmissionType.image, bytes: photo);
    expect(rig.storage.seen.single.raw, small);
  });

  test('the photo is made in the type the slot is signed for', () async {
    for (final type in ['image/jpeg', 'image/webp']) {
      final rig = _Rig()..requestUploadReply = ok(_slot(type: type));
      String? asked;
      await rig
          .submitter(
            prepareImage: (b, mime) async {
              asked = mime;
              return b;
            },
          )
          .submit(
            assignmentId: 'AS-1',
            type: SubmissionType.image,
            bytes: photo,
          );
      expect(asked, type);
    }
  });

  test('a video is uploaded as it is, with no shrinking', () async {
    final rig = _Rig();
    var shrunk = false;
    await rig
        .submitter(
          prepareImage: (b, _) async {
            shrunk = true;
            return b;
          },
        )
        .submit(assignmentId: 'AS-1', type: SubmissionType.video, bytes: photo);
    expect(shrunk, isFalse);
    expect(rig.worker.seen.first.body!['submission_type'], 'video');
  });

  test(
    'a failed upload is retried with the SAME slot (no second slot)',
    () async {
      final rig = _Rig()..uploadReply = (status: 503, body: '');
      final s = rig.submitter();
      await expectLater(
        s.submit(
          assignmentId: 'AS-1',
          type: SubmissionType.image,
          bytes: photo,
        ),
        throwsA(isA<UploadFailedException>()),
      );
      rig.uploadReply = null;
      await s.submit(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
        bytes: photo,
      );
      expect(
        rig.calls.where((c) => c == '/submission/request_upload'),
        hasLength(1),
      );
      expect(
        rig.calls.where((c) => c == '/submission/submit_artwork'),
        hasLength(1),
      );
    },
  );

  test(
    'a failed submit_artwork is retried without uploading again, same key',
    () async {
      final rig = _Rig()..submitReply = failure(502, 'UPSTREAM_ERROR', 'down');
      final s = rig.submitter();
      await expectLater(
        s.submit(
          assignmentId: 'AS-1',
          type: SubmissionType.image,
          bytes: photo,
        ),
        throwsA(isA<ApiException>()),
      );
      rig.submitReply = null;
      await s.submit(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
        bytes: photo,
      );

      expect(rig.calls.where((c) => c == 'PUT'), hasLength(1));
      expect(rig.keys, hasLength(2));
      expect(
        rig.keys[0],
        rig.keys[1],
        reason: 'the key is kept until it works',
      );
    },
  );

  test('upload_not_confirmed means upload again, with the same slot', () async {
    final rig = _Rig()
      ..submitReply = failure(400, 'upload_not_confirmed', 'object missing');
    final s = rig.submitter();
    await expectLater(
      s.submit(assignmentId: 'AS-1', type: SubmissionType.image, bytes: photo),
      throwsA(isA<ApiException>()),
    );
    rig.submitReply = null;
    await s.submit(
      assignmentId: 'AS-1',
      type: SubmissionType.image,
      bytes: photo,
    );

    expect(rig.calls.where((c) => c == 'PUT'), hasLength(2));
    expect(
      rig.calls.where((c) => c == '/submission/request_upload'),
      hasLength(1),
    );
  });

  test(
    'once sent, asking again makes no call and returns the first result',
    () async {
      final rig = _Rig();
      final s = rig.submitter();
      await s.submit(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
        bytes: photo,
      );
      final before = rig.calls.length;
      final again = await s.submit(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
        bytes: photo,
      );
      expect(rig.calls.length, before);
      expect(again.pointsAwarded, 25);
    },
  );

  test('the attempt cap is CONFLICT and nothing is uploaded', () async {
    final rig = _Rig()..requestUploadReply = failure(409, 'CONFLICT', 'cap');
    await expectLater(
      rig.submitter().submit(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
        bytes: photo,
      ),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CONFLICT')),
    );
    expect(rig.calls, ['/submission/request_upload']);
  });

  test(
    'a file over the limit throws, and a smaller file can be sent next',
    () async {
      final rig = _Rig(max: 2);
      final s = rig.submitter();
      await expectLater(
        s.submit(
          assignmentId: 'AS-1',
          type: SubmissionType.video,
          bytes: photo,
        ),
        throwsA(isA<FileTooBigException>()),
      );
      expect(rig.storage.seen, isEmpty);

      // The student chooses a smaller file. The old file is not remembered.
      await s.submit(
        assignmentId: 'AS-1',
        type: SubmissionType.video,
        bytes: Uint8List.fromList([1]),
      );
      expect(rig.storage.seen.single.raw, Uint8List.fromList([1]));
    },
  );

  test('different assignments do not share their state', () async {
    final rig = _Rig();
    final s = rig.submitter();
    await s.submit(
      assignmentId: 'AS-1',
      type: SubmissionType.image,
      bytes: photo,
    );
    await s.submit(
      assignmentId: 'AS-2',
      type: SubmissionType.image,
      bytes: photo,
    );
    expect(
      rig.calls.where((c) => c == '/submission/request_upload'),
      hasLength(2),
    );
  });

  test(
    'send again: a new attempt gets a new slot, a new upload and a new key',
    () async {
      final rig = _Rig();
      final s = rig.submitter();
      await s.submit(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
        bytes: photo,
      );

      s.startNewAttempt('AS-1');
      await s.submit(
        assignmentId: 'AS-1',
        type: SubmissionType.image,
        bytes: photo,
      );

      expect(
        rig.calls.where((c) => c == '/submission/request_upload'),
        hasLength(2),
      );
      expect(rig.calls.where((c) => c == 'PUT'), hasLength(2));
      expect(rig.keys, hasLength(2));
      expect(rig.keys[0], isNot(rig.keys[1]));
    },
  );

  test('startNewAttempt for an assignment never sent is harmless', () async {
    final rig = _Rig();
    final s = rig.submitter()..startNewAttempt('AS-9');
    await s.submit(
      assignmentId: 'AS-9',
      type: SubmissionType.image,
      bytes: photo,
    );
    expect(
      rig.calls.where((c) => c == '/submission/request_upload'),
      hasLength(1),
    );
  });
}
