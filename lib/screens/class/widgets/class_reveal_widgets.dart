import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/activity_models.dart';
import '../../../providers/class_chat_controller.dart';
import '../../../providers/learner_state_provider.dart';
import '../../../providers/reveal_asset_resolver.dart';

class ClassContinueBar extends StatelessWidget {
  const ClassContinueBar({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Continue'),
            ),
          ),
        ),
      ),
    );
  }
}

class ClassPendingActivityChoiceBody extends StatelessWidget {
  const ClassPendingActivityChoiceBody({
    super.key,
    required this.unit,
    required this.onStart,
    required this.onMaybeLater,
  });

  final CourseUnit unit;
  final VoidCallback onStart;
  final VoidCallback onMaybeLater;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Text(
                  'Want to continue?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the next activity when you are ready.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppTheme.subheadingColor),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          unit.thumbnailAsset,
                          width: 112,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 112,
                            height: 96,
                            color: AppTheme.classroomMessageSurface,
                            child: const Icon(
                              Icons.play_circle_fill_rounded,
                              color: AppTheme.buttonColor,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unit.courseDisplay,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.imagePlaceholder,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              unit.unitName,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _EarnRow(
                              icon: Icons.stars_rounded,
                              iconColor: const Color(0xFFE29A22),
                              label: '${unit.totalPoints} Points',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: onStart,
                          child: const Text("Let's go"),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: onMaybeLater,
                          child: const Text('Maybe later'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClassNextActivityInlineCard extends ConsumerWidget {
  const ClassNextActivityInlineCard({
    super.key,
    required this.controller,
    required this.onStartNextActivity,
  });

  final ClassChatController controller;
  final VoidCallback onStartNextActivity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!controller.hasNextUnit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Text(
                'Course complete! 🎉',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You completed every activity in this course.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.subheadingColor),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ref.invalidate(
                      learnerStateDataProvider(controller.learnerId),
                    );
                    context.go(AppRoutes.home);
                  },
                  child: const Text('Back to home'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isWide = MediaQuery.sizeOf(context).width >= 760;
    final previewWidth = isWide ? 210.0 : 96.0;
    final previewHeight = isWide ? 170.0 : 96.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.classroomMessageSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Watch another video?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.subheadingColor,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.volume_up_rounded,
                  size: 16,
                  color: AppTheme.buttonColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: previewWidth,
                    height: previewHeight,
                    color: AppTheme.classroomMessageSurface,
                    child: const Icon(
                      Icons.image_rounded,
                      size: 30,
                      color: AppTheme.imagePlaceholder,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.courseDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.imagePlaceholder,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.nextUnitName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "YOU'LL EARN",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: AppTheme.imagePlaceholder,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _EarnRow(
                        icon: Icons.stars_rounded,
                        iconColor: const Color(0xFFE29A22),
                        label: '${controller.nextUnitPoints} Points',
                      ),
                      const SizedBox(height: 4),
                      const _EarnRow(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppTheme.streakColor,
                        label: '1 streak',
                      ),
                      const SizedBox(height: 4),
                      const _EarnRow(
                        icon: Icons.diamond_rounded,
                        iconColor: AppTheme.buttonColor,
                        label: '1 skill gem',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onStartNextActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Let's go 🎉"),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.invalidate(
                        learnerStateDataProvider(controller.learnerId),
                      );
                      context.go(AppRoutes.home);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mutedLavender,
                      foregroundColor: AppTheme.buttonColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Maybe later'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class ClassWeeklyCapRevealBody extends StatelessWidget {
  const ClassWeeklyCapRevealBody({
    super.key,
    required this.unitIndex,
    required this.onHome,
  });

  final int unitIndex;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F6F9),
      width: double.infinity,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showRail = constraints.maxWidth >= 640;
          final message = Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You did really well this week! 🎉',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You've completed your activities for this week. See you next week!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.subheadingColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.buttonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Back to home'),
                    ),
                  ),
                ],
              ),
            ),
          );

          if (!showRail) return message;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: message),
              SizedBox(
                width: 220,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 16, 20),
                  child: ClassRevealRail(
                    unitIndex: unitIndex,
                    revealProgress: 1,
                    studentName: null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ClassRevealRail extends StatelessWidget {
  const ClassRevealRail({
    super.key,
    required this.unitIndex,
    required this.revealProgress,
    required this.studentName,
  });

  final int unitIndex;
  final double revealProgress;
  final String? studentName;

  @override
  Widget build(BuildContext context) {
    final progress = revealProgress.clamp(0.0, 1.0);
    final revealed = progress >= 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F6E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: AppTheme.streakColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Today's picture",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            revealed
                ? 'Congratulations !!🎉 You have unlocked today\'s picture'
                : 'Complete the activity to reveal the secret character hiding behind the cloud! ☁️✨',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppTheme.subheadingColor,
            ),
          ),
          const SizedBox(height: 12),
          _RevealImage(
            unitIndex: unitIndex,
            revealProgress: progress,
            height: 150,
          ),
        ],
      ),
    );
  }
}

class _RevealImage extends StatelessWidget {
  const _RevealImage({
    required this.unitIndex,
    required this.revealProgress,
    this.height = 150,
  });

  final int unitIndex;
  final double revealProgress;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: RevealAssetResolver.resolve(unitIndex),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: height,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.buttonColor),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: height,
                color: const Color(0xFFDBF4C9),
              ),
              Image.asset(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: height,
                  color: AppTheme.classroomMessageSurface,
                  child: const Icon(
                    Icons.image_rounded,
                    size: 40,
                    color: AppTheme.imagePlaceholder,
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: (1 - revealProgress).clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 500),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 7 * (1 - revealProgress),
                      sigmaY: 7 * (1 - revealProgress),
                    ),
                    child: Container(color: Colors.white.withValues(alpha: 0)),
                  ),
                ),
              ),
              if (revealProgress < 1)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CloudRevealPainter(
                        progress: revealProgress,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              if (revealProgress < 0.95)
                Text(
                  '???',
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2B2B30),
                    shadows: const [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CloudRevealPainter extends CustomPainter {
  const _CloudRevealPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final coverWidth = size.width * (1 - progress.clamp(0.0, 1.0));
    final centerX = size.width / 2;
    final centerY = size.height * 0.48;

    canvas.drawCircle(Offset(centerX, centerY), coverWidth * 0.42, paint);
    canvas.drawCircle(
      Offset(centerX - coverWidth * 0.18, centerY + 8),
      coverWidth * 0.32,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + coverWidth * 0.18, centerY + 6),
      coverWidth * 0.34,
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 20),
        width: coverWidth * 0.82,
        height: coverWidth * 0.34,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudRevealPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
