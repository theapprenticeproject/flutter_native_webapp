import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_primary_button.dart';

enum ClassSectionCheckpointKind { video, submission, quiz, finalWin, generic }

class ClassSectionCheckpoint extends StatelessWidget {
  const ClassSectionCheckpoint({
    super.key,
    required this.kind,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
    this.fillAvailableHeight = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  final ClassSectionCheckpointKind kind;
  final String text;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool fillAvailableHeight;

  /// An optional second choice under the button, for example "Not today".
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    final content = Container(
      width: double.infinity,
      color: AppTheme.classroomBackground,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 32,
        compact ? 44 : 64,
        compact ? 20 : 32,
        40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ClassTapBuddyOrb(size: 160),
              const SizedBox(height: 18),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: compact ? 18 : 20,
                  height: 1.28,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: compact ? double.infinity : 292,
                child: AppPrimaryButton(
                  label: buttonLabel,
                  onPressed: onPressed,
                ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSecondary,
                  child: Text(
                    secondaryLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.buttonColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!fillAvailableHeight) return content;

    return SizedBox.expand(child: SingleChildScrollView(child: content));
  }
}

/// TAP Buddy's circle (design M-C01): soft purple blobs around a dark circle
/// with the TAP Buddy avatar and its name. It does not pulse and does not say
/// "Speaking": there is no audio yet. The speaker icon that plays a clip when
/// the student taps it comes with task D15 (R-17).
class ClassTapBuddyOrb extends StatelessWidget {
  const ClassTapBuddyOrb({super.key, this.size = 136});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = size * 0.66;
    final avatar = size * 0.22;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Three soft blobs, turned a little against each other.
          for (final (angle, alpha) in [(0.0, 0.34), (0.8, 0.3), (1.6, 0.26)])
            Transform.rotate(
              angle: angle,
              child: Container(
                width: size,
                height: size * 0.9,
                decoration: BoxDecoration(
                  color: const Color(0xFF9A8BFF).withValues(alpha: alpha),
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(size / 2, size * 0.45),
                  ),
                ),
              ),
            ),
          Container(
            width: dark,
            height: dark,
            decoration: const BoxDecoration(
              color: Color(0xFF333333),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: avatar,
                  height: avatar,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD7F5D9),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/onboarding/TAP-bot.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.smart_toy_rounded, size: avatar * 0.6),
                  ),
                ),
                SizedBox(height: size * 0.03),
                Text(
                  context.l10n.classTapBuddy,
                  style: GoogleFonts.inter(
                    fontSize: size * 0.06,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
