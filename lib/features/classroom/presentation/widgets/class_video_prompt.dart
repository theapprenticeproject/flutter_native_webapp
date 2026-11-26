import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

/// The bubble above the video (design M-C03): "Watch the video by clicking on the
/// link below… and earn 10 points". The text wraps inside the bubble. It used to
/// sit in a Row with no width limit, so on a narrow phone it was cut off.
class ClassVideoPrompt extends StatelessWidget {
  const ClassVideoPrompt({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.classroomMessageSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: AppTheme.textColor,
        ),
      ),
    );
  }
}
