import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/me/my_projects.dart';
import '../../../domain/submission/feedback_state.dart';
import '../../../l10n/l10n.dart';
import '../project_text.dart';

/// The small state pill of a project (design M-ME-01): orange while the
/// feedback is pending, green when given, red when the work was not right.
class ProjectChip extends StatelessWidget {
  const ProjectChip(this.project, {super.key});

  final MyProject project;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (project.stage) {
      FeedbackStage.valid => (
        const Color(0xFFE7F7EE),
        AppTheme.successGreen,
        Icons.check_rounded,
      ),
      FeedbackStage.waiting || FeedbackStage.slow => (
        const Color(0xFFFDEBD2),
        const Color(0xFFB26A00),
        Icons.schedule_rounded,
      ),
      FeedbackStage.notValid => (
        const Color(0xFFFBE4E4),
        AppTheme.dangerText,
        Icons.warning_amber_rounded,
      ),
      FeedbackStage.notSent => (
        const Color(0xFFEDEDF3),
        AppTheme.subheadingColor,
        Icons.circle_outlined,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            project.labelOf(context.l10n),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
