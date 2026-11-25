import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// The bubble with the photo (or video) the student sent, in the thread under
/// "I made this" (design M-C19). Like the student's other bubbles it is green.
class ClassSubmittedPreview extends StatelessWidget {
  const ClassSubmittedPreview({
    super.key,
    required this.bytes,
    required this.isVideo,
  });

  final Uint8List? bytes;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFFE2F5E9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: isVideo || bytes == null
              ? Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.white,
                  child: Icon(
                    isVideo ? Icons.videocam_rounded : Icons.image_outlined,
                    size: 40,
                    color: AppTheme.imagePlaceholder,
                  ),
                )
              : Image.memory(
                  bytes,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 140,
                    color: Colors.white,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: AppTheme.imagePlaceholder,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
