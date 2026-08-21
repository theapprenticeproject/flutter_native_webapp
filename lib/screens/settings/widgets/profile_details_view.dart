import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/active_profile_model.dart';
import '../../../models/learner_state_model.dart';
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
      return const _ProfileMessageCard(
        message: 'Could not load your profile. Please try again later.',
      );
    }

    final profile = activeProfile;
    if (profile == null) {
      return const _ProfileMessageCard(message: 'No active profile found.');
    }

    final schoolName = learnerState?.profile?.schoolName ?? '—';
    final grade = activeProfile?.grade ?? '—';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StudentSummaryCard(
          studentName: profile.studentName ?? 'Student',
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
          title: 'Personal Details',
          children: [
            _EditableField(
              label: 'First name',
              isEditing: isEditing,
              controller: firstNameController,
            ),
            _EditableField(
              label: 'Last name',
              isEditing: isEditing,
              controller: lastNameController,
            ),
            _EditableField(
              label: 'Language',
              isEditing: isEditing,
              controller: languageController,
            ),
            _ReadOnlyField(
              label: 'Is a brother or sister also using TAP?',
              value: hasSibling ? 'Yes' : 'No',
            ),
            const _ReadOnlyField(label: 'Phone number', value: 'Verified'),
          ],
        ),
        const SizedBox(height: 10),
        _EditableSection(
          title: 'School Details',
          children: [
            _ReadOnlyField(label: 'School Name', value: schoolName),
            _EditableField(
              label: 'Grade',
              isEditing: isEditing,
              controller: gradeController,
            ),
            _ReadOnlyField(
              label: 'Subject',
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
    if (!isEditing) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onStartEditing,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(
            'Edit Info',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.buttonColor,
            side: BorderSide(color: AppTheme.buttonColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

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
                'Cancel',
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
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonColor,
                foregroundColor: AppTheme.cardBackground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.cardBackground,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
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
            backgroundColor: AppTheme.gemBg,
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
                          color: AppTheme.streakColor,
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
                          text: 'Grade $grade',
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
          Icon(icon, size: 15, color: AppTheme.streakColor),
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
