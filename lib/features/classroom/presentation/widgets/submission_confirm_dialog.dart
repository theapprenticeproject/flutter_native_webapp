import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_tonal_button.dart';

/// "Check your work before sending" (design M-S-03): the student sees the photo
/// or video and sends it, or picks another file.
class SubmissionConfirmDialog extends StatelessWidget {
  const SubmissionConfirmDialog({
    super.key,
    required this.bytes,
    required this.isVideo,
    required this.onSend,
    required this.onChange,
  });

  final Uint8List? bytes;
  final bool isVideo;
  final VoidCallback onSend;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.classCheckBeforeSending,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: AppTheme.classroomMessageSurface,
                  child: isVideo || bytes == null
                      ? Icon(
                          isVideo
                              ? Icons.play_circle_fill_rounded
                              : Icons.image_outlined,
                          size: 54,
                          color: AppTheme.buttonColor,
                        )
                      : Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F7EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppTheme.successGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isVideo
                          ? context.l10n.classRightVideo
                          : context.l10n.classRightPhoto,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: context.l10n.classSendToBuddy,
              onPressed: onSend,
            ),
            const SizedBox(height: 8),
            AppTonalButton(
              label: context.l10n.classChangeFile,
              onPressed: onChange,
            ),
          ],
        ),
      ),
    );
  }
}
