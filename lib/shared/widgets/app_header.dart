import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 620;

    if (showBack) {
      return Container(
        height: isCompact ? 64 : 86,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: isCompact ? 72 : 142,
              child: Center(
                child: IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_circle_left_outlined,
                    size: isCompact ? 34 : 44,
                  ),
                  color: const Color(0xFF6E6E7A),
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppTheme.borderColor,
            ),
            SizedBox(width: isCompact ? 16 : 26),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: isCompact ? 13 : 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.subheadingColor,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Container(width: 1, height: 32, color: AppTheme.borderColor),
            if (badge != null) ...[const SizedBox(width: 18), badge!],
            if (showPoints) ...[
              const SizedBox(width: 18),
              _MetricPill(label: '$points'),
            ],
            if (showPoints) ...[
              const SizedBox(width: 18),
              Container(width: 1, height: 32, color: AppTheme.borderColor),
            ],
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 24),
              child: _PostOnboardingBrand(compact: isCompact),
            ),
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
                  child: _PostOnboardingBrand(compact: compact),
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
            children: [_MetricPill(label: context.l10n.headerPoints(points))],
          );

          if (!showStudentSummary) {
            return SizedBox(
              height: compact ? 48 : 54,
              child: Row(
                children: [
                  _PostOnboardingBrand(compact: compact),
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

class _PostOnboardingBrand extends StatelessWidget {
  final bool compact;

  const _PostOnboardingBrand({required this.compact});

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

  const _MetricPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('points-pill'),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E7EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            key: ValueKey('points-coin'),
            width: 20,
            height: 20,
            child: CustomPaint(painter: _CoinPainter()),
          ),
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
