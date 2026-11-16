import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/http_client.dart';
import '../progress/progress_models.dart';

enum SubmissionType { image, video }

/// A place to upload one file, from `/submission/request_upload`.
class UploadSlot {
  const UploadSlot({
    required this.uploadUrl,
    required this.objectKey,
    required this.headers,
    required this.maxSizeBytes,
    required this.attemptNumber,
    required this.attemptsRemaining,
  });

  final String uploadUrl;
  final String objectKey;

  /// Sent as they are with the upload (they are part of the signature).
  final Map<String, String> headers;
  final int maxSizeBytes;
  final int attemptNumber;
  final int attemptsRemaining;

  factory UploadSlot.fromJson(Map<String, dynamic> json) => UploadSlot(
    uploadUrl: json['upload_url'] as String,
    objectKey: json['object_key'] as String,
    headers: {
      for (final e in ((json['upload_headers'] as Map?) ?? const {}).entries)
        e.key.toString(): e.value.toString(),
    },
    maxSizeBytes: (json['max_size_bytes'] as num?)?.toInt() ?? 0,
    attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1,
    attemptsRemaining: (json['attempts_remaining'] as num?)?.toInt() ?? 0,
  );
}

/// The answer of `/submission/submit_artwork`: the work is sent and waits for
/// feedback. The points are the Worker's (+25 for attempt 1).
class ArtworkResult {
  const ArtworkResult({
    required this.submissionId,
    required this.status,
    required this.attemptNumber,
    required this.attemptsRemaining,
    required this.pointsAwarded,
    required this.pointsTotal,
    required this.isRepeat,
  });

  final String submissionId;
  final String status;
  final int attemptNumber;
  final int attemptsRemaining;
  final int pointsAwarded;
  final int? pointsTotal;
  final bool isRepeat;

  bool get isPending => status.toLowerCase() == 'pending';

  factory ArtworkResult.fromJson(Map<String, dynamic> json) => ArtworkResult(
    // shortcut: the test Worker still says "name". Use only submission_id once
    // it is fixed.
    submissionId: (json['submission_id'] ?? json['name'] ?? '') as String,
    status: (json['status'] as String?) ?? '',
    attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1,
    attemptsRemaining: (json['attempts_remaining'] as num?)?.toInt() ?? 0,
    pointsAwarded: (json['points_awarded'] as num?)?.toInt() ?? 0,
    pointsTotal: (json['points_total'] as num?)?.toInt(),
    isRepeat: json['repeat'] == true,
  );
}

/// The file is bigger than the Worker allows. Nothing was sent.
class FileTooBigException implements Exception {
  FileTooBigException(this.size, this.max);
  final int size;
  final int max;

  @override
  String toString() => 'FileTooBigException($size > $max)';
}

/// The upload failed after every try. Nothing was sent to `submit_artwork`.
class UploadFailedException implements Exception {
  @override
  String toString() => 'UploadFailedException';
}

/// The work submission (R-63, R-76): ask for a slot, upload the file to it,
/// then tell the Worker (`submit_artwork`). A student has 2 attempts for each
/// assignment, and a third `request_upload` answers `CONFLICT`.
class SubmissionRepository {
  SubmissionRepository(
    this._http, {
    Dio? uploader,
    this.retryDelay = const Duration(seconds: 1),
    this.skipUpload = AppConstants.skipUpload,
  }) : _uploader = uploader ?? Dio();

  final HttpClient _http;

  /// A plain client with no base address and no token: the signed URL must not
  /// get our bearer token.
  final Dio _uploader;
  final Duration retryDelay;

  /// Test Worker only: do not PUT the file (see [AppConstants.skipUpload]).
  final bool skipUpload;

  static const _uploadTries = 3;

  Future<UploadSlot> requestUpload({
    required String assignmentId,
    required SubmissionType type,
  }) async => UploadSlot.fromJson(
    await _http.postApi(
      '/submission/request_upload',
      body: {'assignment_id': assignmentId, 'submission_type': type.name},
    ),
  );

  /// Uploads the file bytes to the slot. Tries 3 times, then throws
  /// [UploadFailedException]. A file over the limit throws [FileTooBigException]
  /// before any request.
  Future<void> upload(UploadSlot slot, Uint8List bytes) async {
    if (bytes.length > slot.maxSizeBytes) {
      throw FileTooBigException(bytes.length, slot.maxSizeBytes);
    }
    if (skipUpload) return;
    for (var attempt = 1; attempt <= _uploadTries; attempt++) {
      try {
        final response = await _uploader.put<dynamic>(
          slot.uploadUrl,
          data: bytes,
          options: Options(
            headers: slot.headers,
            responseType: ResponseType.plain,
            validateStatus: (_) => true,
          ),
        );
        final status = response.statusCode ?? 0;
        if (status >= 200 && status < 300) return;
      } on DioException catch (e) {
        debugPrint('Upload try $attempt failed: ${e.type}');
      }
      if (attempt < _uploadTries) await Future<void>.delayed(retryDelay);
    }
    throw UploadFailedException();
  }

  Future<ArtworkResult> submitArtwork({
    required String assignmentId,
    required String objectKey,
    required String idempotencyKey,
  }) async => ArtworkResult.fromJson(
    await _http.postApi(
      '/submission/submit_artwork',
      body: {
        'assignment_id': assignmentId,
        'object_key': objectKey,
        'idempotency_key': idempotencyKey,
      },
    ),
  );

  Future<List<SubmissionInfo>> list() async {
    final data = await _http.postApi('/submission/list');
    return [
      for (final raw in (data['submissions'] as List? ?? const []))
        if (raw is Map) SubmissionInfo.fromJson(Map<String, dynamic>.from(raw)),
    ];
  }

  Future<SubmissionInfo> get(String submissionId) async =>
      SubmissionInfo.fromJson(
        await _http.postApi(
          '/submission/get',
          body: {'submission_id': submissionId},
        ),
      );
}
