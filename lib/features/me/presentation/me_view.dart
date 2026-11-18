import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/me/level.dart';
import '../../../domain/me/my_projects.dart';
import '../../../shared/widgets/build_info_toggle.dart';
import '../../../shared/widgets/profile_switcher.dart';

/// The body of Me (R-7): profile, level, points, skill chips, "My projects this
/// year", settings and switch profile. It takes plain data so it is easy to
/// test. v1 leaves out three later items: the profile form (R-74), signing out
/// (R-35) and the theme switch (R-73).
class MeView extends StatelessWidget {
  const MeView({
    required this.studentName,
    required this.grade,
    required this.school,
    required this.points,
    required this.level,
    required this.projects,
    required this.onSwitchProfile,
    required this.onSettings,
    required this.onOpenProject,
    super.key,
  });

  final String studentName;
  final String grade;
  final String? school;
  final int points;

  /// Null when the Worker's tiers are not known.
  final LevelProgress? level;
  final List<MyProject> projects;
  final VoidCallback onSwitchProfile;
  final VoidCallback onSettings;
  final void Function(MyProject) onOpenProject;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SwitchProfileBar(
          studentName: studentName,
          onSwitchDialog: onSwitchProfile,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(name: studentName, grade: grade, school: school),
                  const SizedBox(height: 16),
                  if (level != null) ...[
                    _LevelCard(level: level!),
                    const SizedBox(height: 16),
                  ],
                  _PointsCard(points: points),
                  const SizedBox(height: 22),
                  _ProjectsSection(projects: projects, onOpen: onOpenProject),
                  const SizedBox(height: 22),
                  _SettingsRow(onTap: onSettings),
                  const SizedBox(height: 26),
                  // Long-press "TAP" to see which build this is.
                  Center(
                    child: BuildInfoToggle(
                      child: Text(
                        'TAP',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.imagePlaceholder,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _card() => BoxDecoration(
  color: AppTheme.cardBackground,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppTheme.borderColor),
);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      color: AppTheme.headingText,
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.grade,
    required this.school,
  });

  final String name;
  final String grade;
  final String? school;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (grade.isNotEmpty) 'Class $grade',
      if (school != null && school!.isNotEmpty) school!,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        children: [
          // R-60: the TAP Buddy picture, never a photo of the student.
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE8E8FB),
            child: ClipOval(
              child: Image.asset(
                'assets/profile-screen/tap-buddy-phone-img.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.face_rounded, color: Color(0xFF5B5BD6)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: Color(0xFF5B5BD6),
                    ),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.subheadingColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});
  final LevelProgress level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFC17A43),
              ),
              const SizedBox(width: 8),
              Text(
                level.name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.headingText,
                ),
              ),
              const Spacer(),
              Text(
                level.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.subheadingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: level.fraction,
              minHeight: 6,
              backgroundColor: AppTheme.chatBubble,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.buttonColor,
              ),
            ),
          ),
          if (level.nextName != null) ...[
            const SizedBox(height: 6),
            Text(
              'Next: ${level.nextName}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.subheadingColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFFE29A22), size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$points',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textColor,
                ),
              ),
              Text(
                'Total points',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.subheadingColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'What are points? You earn them by doing TAP activities.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.subheadingColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({required this.projects, required this.onOpen});

  final List<MyProject> projects;
  final void Function(MyProject) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('My projects this year')),
            if (projects.isNotEmpty)
              Text(
                '${doneCount(projects)} / ${projects.length} done',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.subheadingColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (projects.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _card(),
            child: Text(
              'No projects yet. Finish an activity to see it here.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.subheadingColor,
              ),
            ),
          )
        else
          for (final project in projects) ...[
            _ProjectRow(project: project, onTap: () => onOpen(project)),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project, required this.onTap});

  final MyProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _card(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                project.unitName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            Text(
              project.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.subheadingColor,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _card(),
        child: Row(
          children: [
            const Icon(Icons.settings_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
