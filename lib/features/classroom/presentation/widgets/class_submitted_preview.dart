import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';

/// The bubble with the photo (or video) the student sent, in the thread under
/// "I made this" (design M-C19). Like the student's other bubbles it is green.
class ClassSubmittedPreview extends StatelessWidget {
  const ClassSubmittedPreview({
    super.key,
    required this.bytes,
    required this.isVideo,
    this.progress,
  });

  final Uint8List? bytes;
  final bool isVideo;

  /// While the file uploads: 0 to 1. Null (or a null value) shows no line.
  final ValueListenable<double?>? progress;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
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
          if (progress != null)
            ValueListenableBuilder<double?>(
              valueListenable: progress!,
              builder: (context, value, _) => value == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: value,
                            minHeight: 4,
                            color: AppTheme.buttonColor,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.classSendingPercent(
                              (value * 100).round(),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
