import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_primary_button.dart';

/// The screen after the video (design M-C05): the points picture, TAP Buddy's
/// message and Continue. QA bug 6: the picture was a full-width square, the text
/// 18 and the button 76 high, so it covered almost the whole screen.
class ClassVideoRewardCard extends StatelessWidget {
  const ClassVideoRewardCard({
    super.key,
    required this.image,
    required this.text,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String image;
  final String text;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.classroomMessageSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: SizedBox(
                  key: const ValueKey('reward-picture'),
                  height: 240,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(image, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
              decoration: BoxDecoration(
                color: AppTheme.classroomMessageSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                text,
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppPrimaryButton(label: buttonLabel, onPressed: onContinue),
          ],
        ),
      ),
    );
  }
}
