import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/gallery/gallery_models.dart' show initialsOf;
import '../../../domain/me/level.dart';
import '../../../domain/me/my_projects.dart';
import '../../../shared/text/first_name.dart';
import '../../../shared/widgets/app_header.dart'
    show PointsCoin, PostOnboardingBrand;
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/build_info_toggle.dart';
import 'project_journey.dart';
import '../../../shared/widgets/profile_switcher.dart';

/// The body of Me (R-7; design M-ME-01 and M-ME-02): the switch-profile strip,
/// the welcome line with the settings button, profile, level, points, "My
/// projects this year". It takes plain data so it is easy to test. v1 leaves
/// out the profile form (R-74), signing out (R-35), the theme switch (R-73) and
/// deactivate and delete account (R-36).
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
    required this.onStartActivity,
    this.subject,
    super.key,
  });

  final String studentName;
  final String grade;
  final String? school;

  /// The course, for example "Science Lab".
  final String? subject;
  final int points;

  /// Null when the Worker's tiers are not known.
  final LevelProgress? level;
  final List<MyProject> projects;
  final VoidCallback onSwitchProfile;
  final VoidCallback onSettings;
  final void Function(MyProject) onOpenProject;
  final VoidCallback onStartActivity;

  @override
  Widget build(BuildContext context) {
    // A student who has not earned a point yet sees the "start" version.
    final isNew = points == 0;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SwitchProfileBar(
          studentName: firstName(studentName),
          onSwitchDialog: onSwitchProfile,
        ),
        _Top(name: studentName, isNew: isNew, onSettings: onSettings),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(
                    name: studentName,
                    grade: grade,
                    subject: subject,
                    school: school,
                    level: level,
                    isNew: isNew,
                  ),
                  const SizedBox(height: 16),
                  if (level != null) ...[
                    _LevelCard(
                      level: level!,
                      isNew: isNew,
                      onStart: onStartActivity,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _PointsCard(points: points),
                  const SizedBox(height: 22),
                  ProjectJourney(
                    projects: projects,
                    studentName: studentName,
                    onOpen: onOpenProject,
                    onStart: onStartActivity,
                  ),
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
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppTheme.borderColor),
);

/// The white top: the logos, "Welcome Aarav 👋" and the settings button.
class _Top extends StatelessWidget {
  const _Top({
    required this.name,
    required this.isNew,
    required this.onSettings,
  });

  final String name;
  final bool isNew;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PostOnboardingBrand(compact: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.meWelcome(firstName(name)),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isNew
                          ? context.l10n.meSubtitleNew
                          : context.l10n.meSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.subheadingColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.meSettings,
                onPressed: onSettings,
                icon: const Icon(Icons.settings_outlined),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Design M-ME-01: the initials, the name with a tick, class, subject and
/// school, "My level" with the TAP Buddy picture, and the skill chips.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.grade,
    required this.subject,
    required this.school,
    required this.level,
    required this.isNew,
  });

  final String name;
  final String grade;
  final String? subject;
  final String? school;
  final LevelProgress? level;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final skills = [
      context.l10n.meSkill1,
      context.l10n.meSkill2,
      context.l10n.meSkill3,
      context.l10n.meSkill4,
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        children: [
          // R-60: initials, never a photo of the student.
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE8E8FB),
              shape: BoxShape.circle,
            ),
            child: Text(
              initialsOf(name),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.buttonColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
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
                Icons.check_circle_rounded,
                size: 18,
                color: AppTheme.successGreen,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (grade.isNotEmpty)
                _Fact(Icons.menu_book_outlined, context.l10n.meClass(grade)),
              if (subject != null && subject!.isNotEmpty)
                _Fact(Icons.science_outlined, subject!),
            ],
          ),
          if (school != null && school!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _Fact(Icons.school_outlined, school!),
          ],
          if (level != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.borderColor),
            const SizedBox(height: 12),
            Text(
              context.l10n.meMyLevel,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.subheadingColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              level!.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.buttonColor,
              ),
            ),
            if (level!.id == 'bronze') ...[
              const SizedBox(height: 8),
              Image.asset(
                'assets/profile-screen/bronze-buddy.png',
                height: 190,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ],
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 12),
          if (isNew)
            Text(
              context.l10n.meSkillsNone,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textColor),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.meSkillsTitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // shortcut: the same four tags for every student (R-95). The
            // curriculum team gives the real tags later.
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final skill in skills) _SkillChip(skill)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppTheme.successGreen),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.subheadingColor,
          ),
        ),
      ),
    ],
  );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textColor),
    ),
  );
}

/// Design M-ME-01: the level, the bar, the points to go and "Start Activity".
class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.isNew,
    required this.onStart,
  });

  final LevelProgress level;
  final bool isNew;
  final VoidCallback onStart;

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
              if (level.id == 'bronze')
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/profile-screen/bronze-thumb.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(width: 44),
                  ),
                )
              else
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 36,
                  color: Color(0xFFC17A43),
                ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.meYourLevel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.subheadingColor,
                    ),
                  ),
                  Text(
                    level.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.headingText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: level.fraction,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8E8EE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.buttonColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.meLevelPoints(level.label),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
          if (level.nextName != null) ...[
            const SizedBox(height: 2),
            Text(
              isNew
                  ? context.l10n.meFirstActivity
                  : context.l10n.meMorePoints(level.remaining, level.nextName!),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.subheadingColor,
              ),
            ),
          ],
          const SizedBox(height: 14),
          AppPrimaryButton(
            label: context.l10n.meStartActivity,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// Design M-ME-01: the total points, and what points are.
class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDEBD2),
                  shape: BoxShape.circle,
                ),
                child: const PointsCoin(size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.meTotalPoints,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.subheadingColor,
                    ),
                  ),
                  Text(
                    '$points',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEBD2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.mePointsHelpTitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.mePointsHelp,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
