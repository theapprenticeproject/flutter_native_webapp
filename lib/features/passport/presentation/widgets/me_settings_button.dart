import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// Opens Settings, where the student switches profile (R-7, R-34). The Profile
/// tab is gone (R-1), so Me is the way in. The full Me page is task D8.
class MeSettingsButton extends StatelessWidget {
  const MeSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: OutlinedButton.icon(
        onPressed: () => context.go(AppRoutes.profile),
        icon: const Icon(Icons.settings_outlined),
        label: Text(
          'Settings and switch profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.buttonColor,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
