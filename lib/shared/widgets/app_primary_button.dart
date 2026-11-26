import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// The main button of the app: one height, radius, label and colour on every
/// screen (QA bug 13). It was styled separately on each screen, in sizes from 44
/// to 76 high. Full width unless a parent gives it a width. A long label shrinks
/// to stay on one line. [loading] shows a spinner and cannot be pressed.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.tall = false,
  });

  static const double height = 52;

  /// The call-to-action height of the Home card in Figma ("Primary action").
  static const double tallHeight = 56;
  static const double radius = 14;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  /// 56 high, as the Figma button of the Home card, instead of 52.
  final bool tall;

  @override
  Widget build(BuildContext context) {
    // Full width when the parent gives a width; the width of the label when it
    // does not (for example in a Row).
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: tall ? tallHeight : height,
        width: constraints.hasBoundedWidth ? double.infinity : null,
        child: _button(),
      ),
    );
  }

  Widget _button() {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.buttonColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.mutedLavender,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(0, tall ? tallHeight : height),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
