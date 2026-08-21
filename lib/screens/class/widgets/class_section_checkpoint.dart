import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

enum ClassSectionCheckpointKind { video, submission, quiz, finalWin, generic }

class ClassSectionCheckpoint extends StatelessWidget {
  const ClassSectionCheckpoint({
    super.key,
    required this.kind,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
    this.fillAvailableHeight = false,
  });

  final ClassSectionCheckpointKind kind;
  final String text;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool fillAvailableHeight;

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
              const ClassTapBuddySpeakingOrb(size: 160),
              const SizedBox(height: 18),
              const _HearAgainPill(),
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
            ],
          ),
        ),
      ),
    );

    if (!fillAvailableHeight) return content;

    return SizedBox.expand(child: SingleChildScrollView(child: content));
  }
}

class _HearAgainPill extends StatelessWidget {
  const _HearAgainPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.volume_up_rounded,
            size: 15,
            color: AppTheme.buttonColor,
          ),
          const SizedBox(width: 7),
          Text(
            'Hear again',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.buttonColor,
            ),
          ),
        ],
      ),
    );
  }
}

class ClassTapBuddySpeakingOrb extends StatefulWidget {
  const ClassTapBuddySpeakingOrb({super.key, this.size = 136});

  final double size;

  @override
  State<ClassTapBuddySpeakingOrb> createState() =>
      _ClassTapBuddySpeakingOrbState();
}

class _ClassTapBuddySpeakingOrbState extends State<ClassTapBuddySpeakingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final middle = size * 0.85;
    final inner = size * 0.69;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final wave = Curves.easeInOut.transform(_controller.value);
          final reverseWave = Curves.easeInOut.transform(
            (_controller.value + 0.5) % 1,
          );
          final pulse = 1 + (0.025 * (wave < 0.5 ? wave * 2 : (1 - wave) * 2));

          return Stack(
            alignment: Alignment.center,
            children: [
              _SpeakingRipple(
                size: size * (0.88 + wave * 0.18),
                opacity: (0.34 * (1 - wave)).clamp(0.0, 0.34),
              ),
              _SpeakingRipple(
                size: size * (0.78 + reverseWave * 0.22),
                opacity: (0.22 * (1 - reverseWave)).clamp(0.0, 0.22),
              ),
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB9AAFF).withValues(alpha: 0.52),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.scale(
                scale: 1 + ((pulse - 1) * 0.7),
                child: Container(
                  width: middle,
                  height: middle,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8F80FF).withValues(alpha: 0.42),
                    shape: BoxShape.circle,
                  ),
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
                      'TAP Buddy',
                      style: GoogleFonts.inter(
                        fontSize: size * 0.066,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Speaking',
                      style: GoogleFonts.inter(
                        fontSize: size * 0.058,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SpeakingRipple extends StatelessWidget {
  const _SpeakingRipple({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.buttonColor.withValues(alpha: opacity),
          width: 5,
        ),
      ),
    );
  }
}
