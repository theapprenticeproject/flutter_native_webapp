import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/me/my_projects.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_tonal_button.dart';
import '../project_text.dart';
import 'project_chip.dart';

/// The bottom sheet of a project (design M-ME-01): its name, a picture of the
/// work, how it stands, and "See my work".
class ProjectSheet extends StatelessWidget {
  const ProjectSheet({
    required this.project,
    required this.onSeeWork,
    required this.onClose,
    super.key,
  });

  final MyProject project;
  final VoidCallback onSeeWork;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final url = project.viewUrl;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.unitName,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.galleryClose,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F0F4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: url == null
                  ? const Icon(Icons.image_outlined, size: 36)
                  : Image.network(
                      url,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_outlined, size: 36),
                    ),
            ),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: ProjectChip(project)),
            const SizedBox(height: 10),
            Text(
              project.detailOf(context.l10n),
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 14),
            AppTonalButton(
              label: context.l10n.projectSeeMyWork,
              onPressed: onSeeWork,
            ),
          ],
        ),
      ),
    );
  }
}
