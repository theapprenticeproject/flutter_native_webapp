import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {

  static const Color imageBgColor = Color(0xFFE8E8FB);
  static const Color buttonColor = Color(0xFF5B5BD6);
  static const Color bgColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1C1C21);
  static const Color subheadingColor = Color(0xFF6E6E7A);

  static const Color appBackground = Color(0xFFF4F4F6);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color softSurface = Color(0xFFF7F7FA);
  static const Color fieldBackground = Color(0xFFF1F1F4);
  static const Color chatBubble = Color(0xFFEFEFF4);
  static const Color classroomBackground = Color(0xFFFFFFFF);
  static const Color classroomMessageSurface = Color(0xFFEEEEF1);
  static const Color mutedLavender = Color(0xFFE5E4FA);
  static const Color profileBar = Color(0xFFE5E1F1);
  static const Color selectedSurface = Color(0xFFF4F3FF);
  static const Color onboardingBackground = Color(0xFFF5F6FA);
  static const Color onboardingSurface = Color(0xFFF8F9FD);
  static const Color mediaPlaceholder = Color(0xFFF0F0F3);
  static const Color disabledButton = Color(0xFFBDC3C7);
  static const Color imagePlaceholder = Color(0xFFB9BBC8);
  static const Color subtleShadow = Color(0xFF000000);

  static const Color borderColor = Color(0xFFE1E2EA);
  static const Color dividerColor = Color(0xFFD9DAE4);
  static const Color mutedText = Color(0xFF777887);
  static const Color faintText = Color(0xFF8E8E9F);
  static const Color headingText = Color(0xFF111116);

  static const Color pointColor = Color(0xFFF4A22E);
  static const Color pointBg = Color(0xFFFFEBCF);
  static const Color gemBg = Color(0xFFE8E5FF);
  static const Color streakColor = Color(0xFF24A866);
  static const Color streakBg = Color(0xFFDFF5E8);
  static const Color successBubble = Color(0xFFE0F2E6);
  static const Color chatSuccessBubble = Color(0xFFE8FAF1);
  static const Color successText = Color(0xFF0F5132);
  static const Color dangerText = Color(0xFFD34B40);
  static const Color warningSurface = Color(0xFFFFF0D8);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: buttonColor,
        primary: buttonColor,
        surface: bgColor,
        onPrimary: Colors.white,
        onSurface: textColor,
      ),
      textTheme: TextTheme(

        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 36 / 28,
          letterSpacing: -0.005 * 28,
        ),

        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: subheadingColor,
          height: 27 / 18,
          letterSpacing: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
