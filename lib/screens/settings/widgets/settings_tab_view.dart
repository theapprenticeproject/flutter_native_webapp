import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import 'profile_surface.dart';

class SettingsTabView extends StatelessWidget {
  const SettingsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_ThemeCard(), SizedBox(height: 16), _AccountManagementCard()],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    return ProfileWhiteCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          final selector = Container(
            decoration: BoxDecoration(
              color: AppTheme.gemBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: compact
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ThemeButton(
                        label: 'Default',
                        icon: Icons.desktop_windows,
                      ),
                      _ThemeButton(
                        label: 'Light',
                        icon: Icons.wb_sunny_outlined,
                        selected: true,
                      ),
                      _ThemeButton(
                        label: 'Dark',
                        icon: Icons.dark_mode_outlined,
                      ),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ThemeButton(
                        label: 'Default',
                        icon: Icons.desktop_windows,
                      ),
                      _ThemeButton(
                        label: 'Light',
                        icon: Icons.wb_sunny_outlined,
                        selected: true,
                      ),
                      _ThemeButton(
                        label: 'Dark',
                        icon: Icons.dark_mode_outlined,
                      ),
                    ],
                  ),
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsTitle('Theme'),
                const SizedBox(height: 12),
                selector,
              ],
            );
          }

          return Row(
            children: [
              const Expanded(child: _SettingsTitle('Theme')),
              selector,
            ],
          );
        },
      ),
    );
  }
}

class _SettingsTitle extends StatelessWidget {
  const _SettingsTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppTheme.textColor,
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: selected ? AppTheme.buttonColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? AppTheme.cardBackground : AppTheme.buttonColor,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.cardBackground : AppTheme.buttonColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountManagementCard extends StatelessWidget {
  const _AccountManagementCard();

  @override
  Widget build(BuildContext context) {
    return ProfileWhiteCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Management',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Hi Champ, If you need to take a break or want to permanently delete your account, you can manage these options here.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 52,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppTheme.warningSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Deactivate Account',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.dangerText,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Delete Account',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.dangerText,
            ),
          ),
        ],
      ),
    );
  }
}
