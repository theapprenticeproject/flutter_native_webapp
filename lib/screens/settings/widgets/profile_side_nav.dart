import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/profile_tab.dart';

class ProfileSideNav extends StatelessWidget {
  const ProfileSideNav({
    required this.activeTab,
    required this.onChanged,
    this.horizontal = false,
    super.key,
  });

  final ProfileTab activeTab;
  final ValueChanged<ProfileTab> onChanged;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final items = <(ProfileTab, String)>[
      (ProfileTab.profile, 'Profile'),
      (ProfileTab.settings, 'Settings'),
      (ProfileTab.about, 'About TAP'),
    ];

    if (horizontal) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final item in items)
            _NavPill(
              label: item.$2,
              selected: activeTab == item.$1,
              onTap: () => onChanged(item.$1),
            ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items) ...[
          _NavPill(
            label: item.$2,
            selected: activeTab == item.$1,
            onTap: () => onChanged(item.$1),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 116,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.selectedSurface : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.buttonColor : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.buttonColor : AppTheme.subheadingColor,
          ),
        ),
      ),
    );
  }
}
