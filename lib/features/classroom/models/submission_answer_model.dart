import 'dart:typed_data';

enum SubmissionKind { emoji, text, audio, textAudio, image, video, imageVideo }

class SubmissionAnswer {
  const SubmissionAnswer._({
    required this.kind,
    this.text,
    this.emoji,
    this.mediaPath,
    this.bytes,
  });

  final SubmissionKind kind;
  final String? text;
  final String? emoji;
  final String? mediaPath;

  /// The photo or video file, to upload.
  final Uint8List? bytes;

  factory SubmissionAnswer.emoji(String emoji) =>
      SubmissionAnswer._(kind: SubmissionKind.emoji, emoji: emoji);

  factory SubmissionAnswer.text(String text) =>
      SubmissionAnswer._(kind: SubmissionKind.text, text: text);

  factory SubmissionAnswer.audioTranscript(String text) =>
      SubmissionAnswer._(kind: SubmissionKind.textAudio, text: text);

  factory SubmissionAnswer.image(String path, {Uint8List? bytes}) =>
      SubmissionAnswer._(
        kind: SubmissionKind.image,
        mediaPath: path,
        bytes: bytes,
      );

  factory SubmissionAnswer.video(String path, {Uint8List? bytes}) =>
      SubmissionAnswer._(
        kind: SubmissionKind.video,
        mediaPath: path,
        bytes: bytes,
      );

  factory SubmissionAnswer.imageOrVideo(
    String path, {
    required bool isVideo,
    Uint8List? bytes,
  }) => SubmissionAnswer._(
    kind: isVideo ? SubmissionKind.video : SubmissionKind.image,
    mediaPath: path,
    bytes: bytes,
  );

  String get displaySummary {
    switch (kind) {
      case SubmissionKind.emoji:
        return emoji ?? '';
      case SubmissionKind.text:
      case SubmissionKind.textAudio:
        return text ?? '';
      case SubmissionKind.audio:
        return text ?? '🎤 Voice note';
      case SubmissionKind.image:
        return '📷 Photo submitted';
      case SubmissionKind.video:
        return '🎥 Video submitted';
      case SubmissionKind.imageVideo:
        return mediaPath != null && mediaPath!.toLowerCase().endsWith('.mp4')
            ? '🎥 Video submitted'
            : '📷 Photo submitted';
    }
  }

  bool matchesCriteria(String? validCriteria) {
    if (validCriteria == null || validCriteria.trim().isEmpty) return true;

    final candidates = validCriteria
        .toLowerCase()
        .split(RegExp(r'\s*(?:,| or )\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (kind == SubmissionKind.emoji) {
      final value = (emoji ?? '').trim();
      return candidates.any((c) => value.contains(c) || c.contains(value));
    }

    final value = (text ?? '').trim().toLowerCase();
    if (value.isEmpty) return false;
    return candidates.any((c) => value == c || value.contains(c));
  }
}

class SubmissionKindResolver {
  SubmissionKindResolver._();

  static SubmissionKind fromSubTypes(String subTypes) {
    final normalized = subTypes.toLowerCase();
    final hasEmoji = normalized.contains('emoji');
    final hasText = normalized.contains('text');
    final hasAudio = normalized.contains('audio');
    final hasImage = normalized.contains('image');
    final hasVideo = normalized.contains('video');

    if (hasEmoji) return SubmissionKind.emoji;
    if (hasImage && hasVideo) return SubmissionKind.imageVideo;
    if (hasImage) return SubmissionKind.image;
    if (hasVideo) return SubmissionKind.video;
    if (hasText && hasAudio) return SubmissionKind.textAudio;
    if (hasAudio) return SubmissionKind.audio;
    return SubmissionKind.text;
  }
}
