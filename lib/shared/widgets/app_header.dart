import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import 'app_tonal_button.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String studentName;
  final String? subtitle;
  final int points;
  final bool showStudentSummary;
  final bool showBack;
  final bool showPoints;
  final VoidCallback? onBack;

  /// Shown before the points, for example today's picture badge (R-69).
  final Widget? badge;

  /// Shows the "Ask TAP" button and opens the help panel (design M-F2-01).
  final VoidCallback? onAskTap;

  /// The number in the activity header is the points of this activity (the
  /// activity coin), not the student's total (the ring coin).
  final bool pointsAreActivity;

  const AppHeader({
    super.key,
    required this.title,
    this.studentName = 'Aarav',
    this.subtitle,
    this.points = 0,
    this.showStudentSummary = false,
    this.showBack = false,
    this.showPoints = false,
    this.onBack,
    this.badge,
    this.onAskTap,
    this.pointsAreActivity = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 620;

    if (showBack) {
      // Figma Class Header (M-C01, M-C03): 69 high, a 48 round back button, the
      // activity name (only on the start screen), the points (only on the later
      // screens) and "Ask TAP". The logos are not in this header.
      return Container(
        height: 69,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF0F0F4),
                fixedSize: const Size(48, 48),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: title.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                        letterSpacing: 0,
                      ),
                    ),
            ),
            if (badge != null) ...[const SizedBox(width: 8), badge!],
            if (showPoints) ...[
              const SizedBox(width: 8),
              _MetricPill(label: '$points', activity: pointsAreActivity),
            ],
            if (onAskTap != null) ...[
              const SizedBox(width: 8),
              AskTapButton(onPressed: onAskTap!),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 20 : 28,
        isCompact ? 18 : 16,
        isCompact ? 20 : 28,
        0,
      ),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final topRow = Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PostOnboardingBrand(compact: compact),
                ),
              ),
            ],
          );
          final greeting = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.headerHi(studentName),
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(
                  fontSize: compact ? 18 : 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF19191F),
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 7),
                Text(
                  subtitle!,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 12 : 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF777887),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _MetricPill(label: context.l10n.headerPoints(points)),
              if (onAskTap != null) AskTapButton(onPressed: onAskTap!),
            ],
          );

          if (!showStudentSummary) {
            return SizedBox(
              height: compact ? 48 : 54,
              child: Row(
                children: [
                  PostOnboardingBrand(compact: compact),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                topRow,
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: greeting),
                    const SizedBox(width: 12),
                    Flexible(child: actions),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              topRow,
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: greeting),
                  const SizedBox(width: 24),
                  actions,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The two logos with a thin line between them.
class PostOnboardingBrand extends StatelessWidget {
  final bool compact;

  const PostOnboardingBrand({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/logos/gov-logo.png', height: compact ? 26 : 30),
        Container(
          key: const ValueKey('logo-divider'),
          width: 1,
          height: compact ? 26 : 30,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: AppTheme.borderColor,
        ),
        Image.asset(
          'assets/logos/tap-otherLogo.png',
          height: compact ? 26 : 30,
        ),
      ],
    );
  }
}

/// The points pill (design M-F2-01): a ring-shaped coin and the points, 36 high.
class _MetricPill extends StatelessWidget {
  final String label;
  final bool activity;

  const _MetricPill({required this.label, this.activity = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('points-pill'),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E7EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          activity ? const ActivityPointsCoin() : const PointsCoin(),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3A3A46),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// The coin of the points pill, drawn from the design icon (M-F2-01): an orange
/// ring with a diamond in the middle.
class _CoinPainter extends CustomPainter {
  const _CoinPainter();

  static const _orange = Color(0xFFE8A13B);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    canvas.drawCircle(
      c,
      s * 0.45,
      Paint()
        ..color = _orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.1,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s * 0.2, c.dy)
        ..lineTo(c.dx, c.dy - s * 0.3)
        ..lineTo(c.dx + s * 0.2, c.dy)
        ..lineTo(c.dx, c.dy + s * 0.3)
        ..close(),
      Paint()..color = _orange,
    );
  }

  @override
  bool shouldRepaint(covariant _CoinPainter old) => false;
}

/// "Ask TAP": the quiet lavender button of the design that opens the help panel.
class AskTapButton extends StatelessWidget {
  const AskTapButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  // Figma "Ask TAP": 96 wide and 48 high.
  @override
  Widget build(BuildContext context) => AppTonalButton(
    label: context.l10n.headerAskTap,
    onPressed: onPressed,
    height: 48,
    minWidth: 96,
  );
}

/// The points coin: an orange ring with a diamond in the middle (design M-F2-01).
class PointsCoin extends StatelessWidget {
  const PointsCoin({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('points-coin'),
    width: size,
    height: size,
    child: const CustomPaint(painter: _CoinPainter()),
  );
}

/// The coin of the points of ONE activity (Figma, the activity header pill): a
/// dark brown rim, an amber ring, an orange disc and a small white star.
class ActivityPointsCoin extends StatelessWidget {
  const ActivityPointsCoin({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('activity-points-coin'),
    width: size,
    height: size,
    child: const CustomPaint(painter: _ActivityCoinPainter()),
  );
}

class _ActivityCoinPainter extends CustomPainter {
  const _ActivityCoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF9A5B00));
    canvas.drawCircle(c, r * 0.82, Paint()..color = const Color(0xFFC17E1D));
    canvas.drawCircle(c, r * 0.64, Paint()..color = const Color(0xFFE8A13B));
    // A small five-pointed star.
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final radius = (i.isEven ? 0.30 : 0.13) * r;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(
        c.dx + radius * math.cos(angle),
        c.dy + radius * math.sin(angle),
      );
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(star, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ActivityCoinPainter old) => false;
}
