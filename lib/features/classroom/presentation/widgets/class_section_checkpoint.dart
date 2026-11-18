import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

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
                height: 54,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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

/// TAP Buddy's picture. It does not pulse and does not say "speaking": there is
/// no audio yet. The speaker icon that plays a clip when the student taps it
/// comes with task D15 (R-17).
class ClassTapBuddyOrb extends StatelessWidget {
  const ClassTapBuddyOrb({super.key, this.size = 136});

  final double size;

  @override
  Widget build(BuildContext context) {
    final middle = size * 0.85;
    final inner = size * 0.69;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFB9AAFF).withValues(alpha: 0.52),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: middle,
            height: middle,
            decoration: BoxDecoration(
              color: const Color(0xFF8F80FF).withValues(alpha: 0.42),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: inner,
            height: inner,
            decoration: const BoxDecoration(
              color: Color(0xFF292930),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: size * 0.34,
                  height: size * 0.34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9FFE9),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/class-screen/tap_buddy_ai.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.smart_toy_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.l10n.classTapBuddy,
                  style: GoogleFonts.inter(
                    fontSize: size * 0.066,
                    fontWeight: FontWeight.w700,
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
