import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_nav.dart';

/// The Gallery tab (R-1, R-59). This is only the empty state for now: the real
/// Gallery (valid works, initials, the full-screen viewer) is task D9, and the
/// curriculum team's example works fill it at first (R-58).
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppNav(
      child: Scaffold(
        backgroundColor: AppTheme.appBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 56,
                    color: Color(0xFF5B5BD6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The Gallery is coming soon',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Come back to see great work from other students.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.subheadingColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
