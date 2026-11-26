import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/me/my_projects.dart';
import '../../../domain/submission/feedback_state.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../project_text.dart';
import 'project_chip.dart';

/// One project in full (design M-ME-01): its state, when it was sent, the work,
/// and what TAP Buddy thinks. Work that was not right also gets a warning and a
/// way to send it again.
///
/// shortcut: the points of the project (design: "+40 points") are not shown. The
/// Worker's submission list has no points for each work yet.
class ProjectPage extends StatelessWidget {
  const ProjectPage({
    required this.project,
    required this.onSendAgain,
    super.key,
  });

  final MyProject project;
  final VoidCallback onSendAgain;

  String? _sent(BuildContext context) {
    final at = project.createdAt;
    if (at == null) return null;
    final locale = Localizations.localeOf(context).toString();
    try {
      return DateFormat('d MMM, h:mm a', locale).format(at.toLocal());
    } catch (_) {
      return DateFormat('d MMM, h:mm a').format(at.toLocal());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sent = _sent(context);
    final url = project.viewUrl;
    final notRight =
        project.stage == FeedbackStage.notValid ||
        project.stage == FeedbackStage.notValidNoRetry;
    final thinks = switch (project.stage) {
      FeedbackStage.waiting => l.projectThinksWaiting,
      _ => project.detailOf(l),
    };
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F0F4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              project.unitName,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: ProjectChip(project)),
            if (sent != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppTheme.subheadingColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.projectShared(sent),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.subheadingColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Container(
              height: 220,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: url == null
                  ? const Icon(Icons.image_outlined, size: 40)
                  : Image.network(
                      url,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_outlined, size: 40),
                    ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.borderColor),
            const SizedBox(height: 14),
            Text(
              l.projectThinks,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              thinks,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textColor,
              ),
            ),
            if (notRight) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEBD2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE9B565)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Color(0xFFB26A00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.projectWarning,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: const Color(0xFF7A4A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (project.stage == FeedbackStage.notValid) ...[
              const SizedBox(height: 14),
              AppPrimaryButton(
                label: l.projectSendAgain,
                onPressed: onSendAgain,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
