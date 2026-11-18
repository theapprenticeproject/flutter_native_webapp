import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/build_info_toggle.dart';

/// Shown when there is no sign-in. v1 has no password (R-32): the student opens
/// the link that TAP sends on WhatsApp, and the app signs in by itself. There is
/// nothing to type here.
class OpenLinkScreen extends StatelessWidget {
  const OpenLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Long-press the icon to see which build this is.
                  const BuildInfoToggle(
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 56,
                      color: Color(0xFF5B5BD6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Open your TAP link',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Go to the WhatsApp message from TAP and tap the link in it. '
                    'You will come back here and be ready to learn.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.4,
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
