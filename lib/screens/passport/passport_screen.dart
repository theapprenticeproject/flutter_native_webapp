import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/activity_models.dart';
import '../../providers/home_dashboard_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/loading_view.dart';

class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(learningDashboardProvider);

    return AppNav(
      child: Scaffold(
        backgroundColor: AppTheme.appBackground,
        body: dashboardAsync.when(
          loading: () => const LoadingView(),
          error: (err, stack) => Center(child: Text('Failed to load passport')),
          data: (dashboard) => _PassportDashboard(dashboard: dashboard),
        ),
      ),
    );
  }
}

class _PassportDashboard extends StatelessWidget {
  final LearningDashboard dashboard;

  const _PassportDashboard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final progress = dashboard.progress;
    final points = progress.points;
    final gems = progress.skillGems;
    final streak = progress.streakDay;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;

        return SafeArea(
          bottom: false,
          child: Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1060),
              color: AppTheme.cardBackground,
              child: Column(
                children: [
                  AppHeader(
                    title: 'Passport',
                    studentName: progress.studentName,
                    subtitle: 'Have a look at your progress',
                    points: progress.points,
                    streakDay: progress.streakDay,
                    showAskBuddy: true,
                    showStudentSummary: true,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        final horizontalPadding = isWide ? 24.0 : 18.0;
                        final topPadding = isWide ? 44.0 : 28.0;
                        const bottomPadding = 34.0;

                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            topPadding,
                            horizontalPadding,
                            bottomPadding,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(
                                0,
                                bodyConstraints.maxHeight -
                                    topPadding -
                                    bottomPadding,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 840,
                                ),
                                child: isWide
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: _ProgressColumn(
                                              points: points,
                                              gems: gems,
                                              streak: streak,
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          _StudentProfileCard(
                                            studentName: progress.studentName,
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          _ProgressColumn(
                                            points: points,
                                            gems: gems,
                                            streak: streak,
                                          ),
                                          const SizedBox(height: 22),
                                          _StudentProfileCard(
                                            studentName: progress.studentName,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressColumn extends StatelessWidget {
  final int points;
  final int gems;
  final int streak;

  const _ProgressColumn({
    required this.points,
    required this.gems,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RankProgressCard(
          title: 'Bronze Buddy',
          value: points,
          target: 400,
          unitLabel: 'points',
          icon: Icons.workspace_premium_rounded,
          iconBg: const Color(0xFFC17A43),
          iconColor: const Color(0xFF6B3B20),
        ),
        const SizedBox(height: 26),
        Text(
          'Your Achievements Champ!',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppTheme.headingText,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 560;
            final cards = [
              _AchievementCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppTheme.pointColor,
                iconBg: AppTheme.pointBg,
                value: '$points',
                label: 'Points',
                title: 'What are points',
                description: 'Earn points by doing TAP Activities every week!',
              ),
              _AchievementCard(
                icon: Icons.diamond_rounded,
                iconColor: AppTheme.buttonColor,
                iconBg: AppTheme.gemBg,
                value: '$gems',
                label: 'Skill Gems',
                title: 'What are skill gems',
                description:
                    'You earn 1 skill gem for every submission you make.',
              ),
              _AchievementCard(
                icon: Icons.water_drop_rounded,
                iconColor: AppTheme.streakColor,
                iconBg: AppTheme.streakBg,
                value: '$streak',
                label: 'Streak',
                title: 'What are streaks',
                description:
                    'If you forget to submit your streak resets to zero.',
              ),
            ];

            if (narrow) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final card in cards) ...[
                      SizedBox(width: 150, child: card),
                      if (card != cards.last) const SizedBox(width: 10),
                    ],
                  ],
                ),
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (final card in cards) ...[
                  SizedBox(width: 150, child: card),
                  if (card != cards.last) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RankProgressCard extends StatelessWidget {
  final String title;
  final int value;
  final int target;
  final String unitLabel;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _RankProgressCard({
    required this.title,
    required this.value,
    required this.target,
    required this.unitLabel,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, target);
    final remaining = target - clamped;

    return Container(
      width: double.infinity,
      height: 78,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.headingText,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: target == 0 ? 0 : clamped / target,
                    minHeight: 4,
                    backgroundColor: AppTheme.chatBubble,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.buttonColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$clamped/$target',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.headingText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$remaining $unitLabel remaining',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.headingText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, color: iconColor, size: 19),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final String title;
  final String description;

  const _AchievementCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.title,
    required this.description,
  });

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _hovered = !_hovered),
        child: SizedBox(
          width: double.infinity,
          height: 140,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              return AnimatedBuilder(
                animation: animation,
                child: child,
                builder: (context, child) {
                  final rotation = (1 - animation.value) * math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(rotation),
                    child: child,
                  );
                },
              );
            },
            child: _hovered
                ? _AchievementBack(
                    key: ValueKey('${widget.label}-back'),
                    icon: widget.icon,
                    iconColor: widget.iconColor,
                    iconBg: widget.iconBg,
                    title: widget.title,
                    description: widget.description,
                  )
                : _AchievementFront(
                    key: ValueKey('${widget.label}-front'),
                    icon: widget.icon,
                    iconColor: widget.iconColor,
                    iconBg: widget.iconBg,
                    value: widget.value,
                    label: widget.label,
                  ),
          ),
        ),
      ),
    );
  }
}

class _AchievementFront extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _AchievementFront({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AchievementIcon(icon: icon, iconColor: iconColor, iconBg: iconBg),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppTheme.subheadingColor,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: AppTheme.subheadingColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementBack extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;

  const _AchievementBack({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 150;
        final textColumn = Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: compact ? TextAlign.center : TextAlign.left,
              style: GoogleFonts.inter(
                fontSize: compact ? 11 : 13,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: AppTheme.subheadingColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: compact ? 4 : 5,
              overflow: TextOverflow.ellipsis,
              textAlign: compact ? TextAlign.center : TextAlign.left,
              style: GoogleFonts.inter(
                fontSize: compact ? 10 : 11,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        );

        return Container(
          height: 132,
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: compact
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AchievementIcon(
                      icon: icon,
                      iconColor: iconColor,
                      iconBg: iconBg,
                      small: true,
                    ),
                    const SizedBox(height: 8),
                    Flexible(child: textColumn),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AchievementIcon(
                      icon: icon,
                      iconColor: iconColor,
                      iconBg: iconBg,
                      small: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: textColumn),
                  ],
                ),
        );
      },
    );
  }
}

class _AchievementIcon extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool small;

  const _AchievementIcon({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 38.0 : 54.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: small ? 20 : 26),
    );
  }
}

class _StudentProfileCard extends StatelessWidget {
  final String studentName;

  const _StudentProfileCard({required this.studentName});

  @override
  Widget build(BuildContext context) {
    final initials = studentName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: 240,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E2EA)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8E5FF),
            child: Text(
              initials.isEmpty ? 'AK' : initials,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.buttonColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            studentName,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF25252C),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Junior Buddy 🌱',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF777887),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: Color(0xFF24A866),
              ),
              const SizedBox(width: 5),
              Text(
                'Grade 4',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6F7080),
                ),
              ),
              const SizedBox(width: 10),
              const Text('•', style: TextStyle(color: Color(0xFF8E8E9F))),
              const SizedBox(width: 10),
              const Icon(Icons.hub_rounded, size: 16, color: Color(0xFF24A866)),
              const SizedBox(width: 5),
              Text(
                'Science Lab',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6F7080),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Image.asset(
            'assets/class-screen/Skill Passport 1.png',
            height: 220,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
