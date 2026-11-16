import 'dart:typed_data';

import '../../core/network/api_exception.dart';
import '../progress/idempotency_key.dart';
import 'submission_repository.dart';

class _Attempt {
  UploadSlot? slot;
  bool uploaded = false;
  String? key;
  ArtworkResult? done;
}

/// Sends one piece of work to the Worker: slot, upload, `submit_artwork`.
///
/// It remembers how far each assignment got. A retry after a failure starts at
/// the step that failed, with the same slot and the same idempotency key, so it
/// never asks for a second slot and cannot send the work twice. Once sent, it
/// returns the first result and makes no call.
class WorkSubmitter {
  WorkSubmitter(this._repo, {required this.studentId, this.prepareImage});

  final SubmissionRepository _repo;
  final String studentId;

  /// Makes a photo smaller before the upload (WebP). A video is not changed.
  final Future<Uint8List> Function(Uint8List)? prepareImage;

  final Map<String, _Attempt> _attempts = {};

  Future<ArtworkResult> submit({
    required String assignmentId,
    required SubmissionType type,
    required Uint8List bytes,
  }) async {
    final attempt = _attempts.putIfAbsent(assignmentId, _Attempt.new);
    final done = attempt.done;
    if (done != null) return done;

    attempt.slot ??= await _repo.requestUpload(
      assignmentId: assignmentId,
      type: type,
    );
    if (!attempt.uploaded) {
      final shrink = prepareImage;
      final file = type == SubmissionType.image && shrink != null
          ? await shrink(bytes)
          : bytes;
      await _repo.upload(attempt.slot!, file);
      attempt.uploaded = true;
    }

    attempt.key ??= newIdempotencyKey('artwork', studentId, assignmentId);
    try {
      return attempt.done = await _repo.submitArtwork(
        assignmentId: assignmentId,
        objectKey: attempt.slot!.objectKey,
        idempotencyKey: attempt.key!,
      );
    } on ApiException catch (e) {
      // The Worker could not find or accept the file: upload it again.
      const uploadProblems = {
        'upload_not_confirmed',
        'upload_size_invalid',
        'upload_type_mismatch',
      };
      if (uploadProblems.contains(e.code)) attempt.uploaded = false;
      rethrow;
    }
  }
}
