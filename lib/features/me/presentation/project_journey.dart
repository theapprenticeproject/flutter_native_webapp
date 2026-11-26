import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/gallery/gallery_models.dart' show initialsOf;
import '../../../domain/me/my_projects.dart';
import '../../../domain/submission/feedback_state.dart';
import '../../../l10n/l10n.dart';
import '../project_text.dart';

/// "My projects this year" as a path (design M-ME-01): the projects with valid
/// feedback are done, the first one that is not is where the student is, and
/// the rest are locked. Tapping a done or current project opens it.
///
/// shortcut: every node has the same icon, because no project has art yet. The
/// "Halfway there! ... 2026-27" line of the design is left out: no data says
/// which school year it is.
class ProjectJourney extends StatelessWidget {
  const ProjectJourney({
    required this.projects,
    required this.studentName,
    required this.onOpen,
    required this.onStart,
    super.key,
  });

  final List<MyProject> projects;
  final String studentName;
  final void Function(MyProject) onOpen;

  /// "Start Activity": the student goes to Home, where the activity waits.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final nodes = projectPath(projects);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.meProjectsTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.headingText,
                  ),
                ),
              ),
              if (projects.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.meProjectsDone(
                      doneCount(projects),
                      projects.length,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.buttonColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (projects.isEmpty)
            Text(
              context.l10n.meNoProjects,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.subheadingColor,
              ),
            )
          else ...[
            Text(
              context.l10n.meProjectsHint,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.subheadingColor,
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < nodes.length; i++) ...[
              _Node(
                node: nodes[i],
                studentName: studentName,
                onOpen: onOpen,
                onStart: onStart,
              ),
              if (i < nodes.length - 1) const _Connector(),
            ],
          ],
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(width: 3, height: 26, color: const Color(0xFFD9D9EE)),
  );
}

class _Node extends StatelessWidget {
  const _Node({
    required this.node,
    required this.studentName,
    required this.onOpen,
    required this.onStart,
  });

  final PathNode node;
  final String studentName;
  final void Function(MyProject) onOpen;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = node.project;
    final locked = node.state == PathState.locked;
    final current = node.state == PathState.current;
    final upNext = current && p.stage == FeedbackStage.notSent;

    final circle = Container(
      width: current ? 76 : 58,
      height: current ? 76 : 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locked ? const Color(0xFFE3E3EC) : AppTheme.buttonColor,
        border: current
            ? Border.all(color: const Color(0xFFC9C9F2), width: 6)
            : null,
      ),
      child: Icon(
        locked
            ? Icons.lock_outline_rounded
            : node.state == PathState.done
            ? Icons.check_rounded
            : Icons.palette_outlined,
        size: current ? 32 : 26,
        color: locked ? AppTheme.imagePlaceholder : Colors.white,
      ),
    );

    final label = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          locked ? l.meProjectN(node.number) : p.unitName,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: locked ? AppTheme.subheadingColor : AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          locked
              ? l.meUnlocksSoon
              : upNext
              ? l.meUpNext
              : p.labelOf(l),
          style: GoogleFonts.inter(
            fontSize: 11,
            color: current ? AppTheme.buttonColor : AppTheme.subheadingColor,
          ),
        ),
      ],
    );

    return InkWell(
      onTap: locked ? null : (upNext ? onStart : () => onOpen(p)),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            if (upNext)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.buttonColor, width: 1.5),
                ),
                child: Text(
                  l.meStartActivity,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.buttonColor,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (current)
                  SizedBox(
                    width: 84,
                    child: _YouAreHere(studentName: studentName),
                  )
                else
                  const SizedBox(width: 84),
                circle,
                const SizedBox(width: 84),
              ],
            ),
            const SizedBox(height: 8),
            label,
          ],
        ),
      ),
    );
  }
}

/// "You are here" with the student's initials, left of the current project.
class _YouAreHere extends StatelessWidget {
  const _YouAreHere({required this.studentName});

  final String studentName;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.buttonColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          context.l10n.meYouAreHere,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8FB),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          initialsOf(studentName),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.buttonColor,
          ),
        ),
      ),
    ],
  );
}
