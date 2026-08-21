import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import 'app_nav.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String studentName;
  final String subtitle;
  final int points;
  final int streakDay;
  final VoidCallback? onAskBuddy;
  final bool showAskBuddy;
  final bool showStudentSummary;
  final bool showBack;
  final bool showPoints;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    this.studentName = 'Aarav',
    this.subtitle = "Ready for today's class?",
    this.points = 0,
    this.streakDay = 0,
    this.onAskBuddy,
    this.showAskBuddy = false,
    this.showStudentSummary = false,
    this.showBack = false,
    this.showPoints = false,
    this.onBack,
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
            if (showPoints) ...[
              const SizedBox(width: 18),
              _MetricPill(
                icon: Icons.stars_rounded,
                iconColor: const Color(0xFFE29A22),
                label: '$points',
              ),
            ],
            if (showAskBuddy) ...[
              const SizedBox(width: 14),
              _AskBuddyButton(
                onPressed:
                    onAskBuddy ??
                    () {
                      TapBuddyScope.maybeOpenOf(context)?.call();
                    },
              ),
            ],
            if (showPoints || showAskBuddy) ...[
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
          void openBuddy() {
            final openPanel = TapBuddyScope.maybeOpenOf(context);
            if (onAskBuddy != null) {
              onAskBuddy!();
            } else {
              openPanel?.call();
            }
          }

          final topRow = Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PostOnboardingBrand(compact: compact),
                ),
              ),
              if (showAskBuddy) ...[
                const SizedBox(width: 12),
                _AskBuddyButton(onPressed: openBuddy),
              ],
            ],
          );
          final greeting = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi $studentName 👋',
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(
                  fontSize: compact ? 18 : 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF19191F),
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(
                  fontSize: compact ? 12 : 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF777887),
                  letterSpacing: 0,
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _MetricPill(
                icon: Icons.stars_rounded,
                iconColor: const Color(0xFFE29A22),
                label: '$points',
              ),
              _MetricPill(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFF28B36A),
                label: 'Day $streakDay',
              ),
            ],
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
                  if (showAskBuddy) ...[
                    const SizedBox(width: 12),
                    _AskBuddyButton(onPressed: openBuddy),
                  ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
        SizedBox(width: compact ? 12 : 9),
        Image.asset(
          'assets/logos/tap-otherLogo.png',
          height: compact ? 26 : 30,
        ),
      ],
    );
  }
}

class _AskBuddyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AskBuddyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F2FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF8A82EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 13,
              color: Color(0xFF5B5BD6),
            ),
            const SizedBox(width: 5),
            Text(
              'Ask TAP Buddy',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A46),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _MetricPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E7EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A46),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
