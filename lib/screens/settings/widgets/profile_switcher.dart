import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/profile_summary_model.dart';
import '../../../providers/profile_provider.dart';

class SwitchProfileBar extends StatelessWidget {
  const SwitchProfileBar({
    required this.studentName,
    required this.onSwitchDialog,
    super.key,
  });

  final String studentName;
  final VoidCallback onSwitchDialog;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return ColoredBox(
      color: AppTheme.profileBar,
      child: SizedBox(
        width: screenWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : screenWidth;
              final compact = availableWidth < 380;

              final text = Text(
                'Not $studentName? Switch to your profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              );

              final button = _SwitchProfileButton(
                label: 'Switch Profile',
                onPressed: onSwitchDialog,
              );

              if (compact) {
                return SizedBox(
                  width: availableWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [text, const SizedBox(height: 10), button],
                  ),
                );
              }

              return SizedBox(
                width: availableWidth,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [text, const SizedBox(width: 18), button],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SwitchProfileDialog extends ConsumerStatefulWidget {
  const SwitchProfileDialog({
    required this.phone,
    required this.activeLearnerId,
    required this.onProfileSelected,
    super.key,
  });

  final String phone;
  final String? activeLearnerId;
  final Future<void> Function(ProfileSummaryModel) onProfileSelected;

  @override
  ConsumerState<SwitchProfileDialog> createState() =>
      _SwitchProfileDialogState();
}

class _SwitchProfileDialogState extends ConsumerState<SwitchProfileDialog> {
  String? _switchingLearnerId;

  Future<void> _handleTap(ProfileSummaryModel profile) async {
    setState(() => _switchingLearnerId = profile.learnerId);
    await widget.onProfileSelected(profile);
    if (mounted) setState(() => _switchingLearnerId = null);
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(
      profilesPageDataProvider(ProfilesPageRequest(phone: widget.phone)),
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Switch Profile',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.fieldBackground,
                    ),
                  ),
                ],
              ),
              Text(
                'Hi Champ, please select who I will talk to',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              const SizedBox(height: 18),
              profilesAsync.when(
                data: (profiles) {
                  if (profiles.isEmpty) {
                    return Text(
                      'No student profiles found for this account.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.subheadingColor,
                      ),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < profiles.length; i++) ...[
                        _ProfileOption(
                          profile: profiles[i],
                          selected:
                              profiles[i].learnerId == widget.activeLearnerId,
                          loading: _switchingLearnerId == profiles[i].learnerId,
                          onTap: _switchingLearnerId == null
                              ? () => _handleTap(profiles[i])
                              : null,
                        ),
                        if (i != profiles.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Text(
                  'Could not load profiles. Please try again.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.dangerText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchProfileButton extends StatelessWidget {
  const _SwitchProfileButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.buttonColor,
          foregroundColor: AppTheme.cardBackground,
          elevation: 0,
          minimumSize: Size.zero,
          fixedSize: const Size(132, 42),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.profile,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final ProfileSummaryModel profile;
  final bool selected;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (profile.grade != null) 'Grade ${profile.grade}',
      if (profile.division != null) profile.division,
    ].join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gemBg : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.gemBg,
              child: Text(
                _initials(profile.studentName),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.buttonColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.studentName.isEmpty
                        ? 'Student'
                        : profile.studentName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.subheadingColor,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  selected ? 'Selected ✓' : 'Select',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.buttonColor : AppTheme.textColor,
                  ),
                ),
              ),
          ],
        ),
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
