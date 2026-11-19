import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/learning_progress/activity_models.dart';
import '../../providers/class_chat_controller.dart';
import '../../../../domain/learner/learner_state_provider.dart';
import '../../providers/reveal_asset_resolver.dart';
import 'picture_quarters.dart';

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
              child: Text(context.l10n.buttonContinue),
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
                  context.l10n.classWantToContinue,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.classStartNext,
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
                          child: Text(context.l10n.classLetsGo),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: onMaybeLater,
                          child: Text(context.l10n.classMaybeLater),
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
                context.l10n.classCourseComplete,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.classCourseCompleteBody,
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
                  child: Text(context.l10n.classBackHome),
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
                  context.l10n.classWatchAnother,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.subheadingColor,
                  ),
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
                        context.l10n.classYoullEarn,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: AppTheme.imagePlaceholder,
                        ),
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
                    child: Text(context.l10n.homeLetsGo),
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
                    child: Text(context.l10n.classMaybeLater),
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

class ClassNoActivityBody extends StatelessWidget {
  const ClassNoActivityBody({
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
                    context.l10n.classDidWell,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.classFinishedForNow,
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
                      child: Text(context.l10n.classBackHome),
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
                  color: AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.classTodaysPicture,
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
                ? context.l10n.classPictureUnlocked
                : context.l10n.classPictureLocked,
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

/// The picture, revealed as far as [revealProgress] (0 to 1).
class ClassRevealPicture extends StatelessWidget {
  const ClassRevealPicture({
    super.key,
    required this.unitIndex,
    required this.revealProgress,
    this.height = 240,
  });

  final int unitIndex;
  final double revealProgress;
  final double height;

  @override
  Widget build(BuildContext context) => _RevealImage(
    unitIndex: unitIndex,
    revealProgress: revealProgress,
    height: height,
  );
}

/// The "Today's picture" sheet (design M-C26b): the picture in quarters, 4
/// progress bars, and a line that says how far the student is. It opens by
/// itself when the 4th piece unlocks, and when the student taps the badge.
Future<void> showRevealSheet(
  BuildContext context, {
  required int unitIndex,
  required int pieces,
  String? asset,
}) {
  final n = pieces.clamp(0, 4);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.classTodaysPicture,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 240,
                child: asset != null
                    ? PictureQuarters(asset: asset, pieces: n, radius: 20)
                    : FutureBuilder<String>(
                        future: RevealAssetResolver.resolve(unitIndex),
                        builder: (context, snapshot) => PictureQuarters(
                          asset: snapshot.data,
                          pieces: n,
                          radius: 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: 240,
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          key: ValueKey(
                            'picture-bar-$i-${i < n ? 'on' : 'off'}',
                          ),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < n
                                ? AppTheme.buttonColor
                                : const Color(0xFFE4E4FB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              n >= 4
                  ? context.l10n.classPictureFullTitle
                  : context.l10n.classPicturePartTitle(n),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              n >= 4
                  ? context.l10n.classPictureFullBody
                  : context.l10n.classPicturePartBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.subheadingColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
      builder: (context, snapshot) => Center(
        child: SizedBox(
          width: height,
          child: PictureQuarters(
            asset: snapshot.data,
            pieces: (revealProgress.clamp(0.0, 1.0) * 4).round(),
          ),
        ),
      ),
    );
  }
}
