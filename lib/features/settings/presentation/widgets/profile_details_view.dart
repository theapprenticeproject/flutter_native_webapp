import '../../../../shared/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/profile/active_profile_model.dart';
import '../../../../domain/learner/learner_state_model.dart';
import 'profile_surface.dart';

class ProfileDetailsView extends StatelessWidget {
  const ProfileDetailsView({
    required this.isLoading,
    required this.loadFailed,
    required this.isEditing,
    required this.isSaving,
    required this.saveError,
    required this.activeProfile,
    required this.learnerState,
    required this.firstNameController,
    required this.lastNameController,
    required this.languageController,
    required this.gradeController,
    required this.subjectDisplay,
    required this.hasSibling,
    required this.onStartEditing,
    required this.onCancelEditing,
    required this.onSave,
    super.key,
  });

  final bool isLoading;
  final bool loadFailed;
  final bool isEditing;
  final bool isSaving;
  final String? saveError;
  final ActiveProfileModel? activeProfile;
  final LearnerStateModel? learnerState;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController languageController;
  final TextEditingController gradeController;
  final String subjectDisplay;
  final bool hasSibling;
  final VoidCallback onStartEditing;
  final VoidCallback onCancelEditing;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ProfileSkeleton();
    }

    if (loadFailed) {
      return _ProfileMessageCard(
        message: context.l10n.settingsProfileLoadFailed,
      );
    }

    final profile = activeProfile;
    if (profile == null) {
      return _ProfileMessageCard(message: context.l10n.settingsNoProfile);
    }

    final schoolName = learnerState?.profile?.schoolName ?? '—';
    final grade = activeProfile?.grade ?? '—';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StudentSummaryCard(
          studentName: profile.studentName ?? context.l10n.profileStudent,
          schoolName: schoolName,
          grade: grade,
          subjectDisplay: subjectDisplay,
        ),
        const SizedBox(height: 16),
        if (saveError != null) ...[
          _ErrorBanner(text: saveError!),
          const SizedBox(height: 12),
        ],
        _EditableSection(
          title: context.l10n.settingsPersonal,
          children: [
            _EditableField(
              label: context.l10n.settingsFirstName,
              isEditing: isEditing,
              controller: firstNameController,
            ),
            _EditableField(
              label: context.l10n.settingsLastName,
              isEditing: isEditing,
              controller: lastNameController,
            ),
            _EditableField(
              label: context.l10n.settingsLanguage,
              isEditing: isEditing,
              controller: languageController,
            ),
            _ReadOnlyField(
              label: context.l10n.settingsSibling,
              value: hasSibling
                  ? context.l10n.settingsYes
                  : context.l10n.settingsNo,
            ),
            _ReadOnlyField(
              label: context.l10n.settingsPhone,
              value: context.l10n.settingsVerified,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _EditableSection(
          title: context.l10n.settingsSchoolDetails,
          children: [
            _ReadOnlyField(
              label: context.l10n.settingsSchoolName,
              value: schoolName,
            ),
            _EditableField(
              label: context.l10n.settingsGrade,
              isEditing: isEditing,
              controller: gradeController,
            ),
            _ReadOnlyField(
              label: context.l10n.settingsSubject,
              value: subjectDisplay.isEmpty ? '—' : subjectDisplay,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _EditActionsBar(
          isEditing: isEditing,
          isSaving: isSaving,
          onStartEditing: onStartEditing,
          onCancelEditing: onCancelEditing,
          onSave: onSave,
        ),
      ],
    );
  }
}

class _ProfileMessageCard extends StatelessWidget {
  const _ProfileMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ProfileWhiteCard(
      padding: const EdgeInsets.all(18),
      child: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subheadingColor),
      ),
    );
  }
}

class _EditActionsBar extends StatelessWidget {
  const _EditActionsBar({
    required this.isEditing,
    required this.isSaving,
    required this.onStartEditing,
    required this.onCancelEditing,
    required this.onSave,
  });

  final bool isEditing;
  final bool isSaving;
  final VoidCallback onStartEditing;
  final VoidCallback onCancelEditing;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    // Edit profile is later (R-74): v1 shows the data and does not save it.
    if (!isEditing) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: isSaving ? null : onCancelEditing,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.subheadingColor,
                side: const BorderSide(color: AppTheme.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                context.l10n.buttonCancel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppPrimaryButton(
            label: context.l10n.settingsSaveChanges,
            loading: isSaving,
            onPressed: onSave,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warningSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dangerText),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.dangerText,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.dangerText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentSummaryCard extends StatelessWidget {
  const _StudentSummaryCard({
    required this.studentName,
    required this.schoolName,
    required this.grade,
    required this.subjectDisplay,
  });

  final String studentName;
  final String schoolName;
  final String grade;
  final String subjectDisplay;

  @override
  Widget build(BuildContext context) {
    return ProfileWhiteCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.softLavender,
            child: Text(
              _initials(studentName),
              style: const TextStyle(color: AppTheme.buttonColor),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textWidth = constraints.maxWidth;
                final compact = textWidth < 230;
                final subjectWidth = compact
                    ? textWidth
                    : (textWidth - 14) * 0.58;
                final gradeWidth = compact
                    ? textWidth
                    : (textWidth - 14) * 0.36;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppTheme.successGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _MetaLine(
                      icon: Icons.location_city_rounded,
                      text: schoolName,
                      width: textWidth,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _MetaLine(
                          icon: Icons.menu_book_rounded,
                          text: context.l10n.profileGrade(grade),
                          width: gradeWidth,
                        ),
                        if (subjectDisplay.isNotEmpty)
                          _MetaLine(
                            icon: Icons.hub_rounded,
                            text: subjectDisplay,
                            width: subjectWidth,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    required this.width,
  });

  final IconData icon;
  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.successGreen),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.subheadingColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableSection extends StatelessWidget {
  const _EditableSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ProfileWhiteCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            height: 36,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.fieldBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.subheadingColor,
                    ),
                  ),
                ),
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: AppTheme.faintText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.isEditing,
    required this.controller,
  });

  final String label;
  final bool isEditing;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 5),
          if (isEditing)
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.buttonColor),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: controller,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 36,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.fieldBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                controller.text.isEmpty ? '—' : controller.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.subheadingColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppTheme.subheadingColor,
      ),
    );
  }
}
