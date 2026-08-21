import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/router.dart';
import '../../models/activity_models.dart';
import '../../providers/home_dashboard_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/loading_view.dart';
import 'widgets/completed_card.dart';
import 'widgets/home_buddy_art.dart';
import 'widgets/quiz_pending_card.dart';
import 'widgets/send_project_card.dart';
import 'widgets/start_activity_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(learningDashboardProvider);

    return AppNav(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F6),
        body: dashboardAsync.when(
          loading: () => const LoadingView(),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(_errorMessage(err), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(learningDashboardProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (dashboard) => _HomeDashboard(
            dashboard: dashboard,
            onContinue: () => context.go(AppRoutes.classroom),
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object err) {
    if (err is NoActiveProfileException) {
      return 'No profile selected. Please sign in again.';
    }
    return 'Failed to load dashboard: $err';
  }
}

class _HomeDashboard extends StatelessWidget {
  final LearningDashboard dashboard;
  final VoidCallback onContinue;

  const _HomeDashboard({required this.dashboard, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final progress = dashboard.progress;
    final stage = dashboard.showCompletionCelebration ||
            dashboard.hasReachedWeeklyCap ||
            dashboard.unit == null
        ? LearningStage.completed
        : progress.currentStage;
    final unit = dashboard.unit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontalPadding = switch (constraints.maxWidth) {
          >= 980 => 24.0,
          >= 640 => 20.0,
          _ => 16.0,
        };

        return SafeArea(
          bottom: false,
          child: Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1060),
              color: Colors.white,
              child: Column(
                children: [
                  AppHeader(
                    title: 'Home',
                    studentName: progress.studentName,
                    points: progress.points,
                    streakDay: progress.streakDay,
                    showAskBuddy: true,
                    showStudentSummary: true,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isWide ? 56 : 38,
                        horizontalPadding,
                        34,
                      ),
                      child: !dashboard.hasEnrollment
                          ? const _NoEnrollmentState()
                          : _StageContent(
                              stage: stage,
                              unit: unit,
                              hasReachedWeeklyCap:
                                  dashboard.hasReachedWeeklyCap,
                              isWide: isWide,
                              completionPoints: dashboard.completionPoints,
                              onContinue: dashboard.showCompletionCelebration
                                  ? onContinue
                                  : null,
                            ),
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

class _NoEnrollmentState extends StatelessWidget {
  const _NoEnrollmentState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 48, color: Color(0xFFB9BBC8)),
          const SizedBox(height: 16),
          const Text(
            'No course enrolled yet.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.onboarding),
            child: const Text('Choose a course'),
          ),
        ],
      ),
    );
  }
}

class _StageContent extends StatelessWidget {
  final LearningStage stage;
  final CourseUnit? unit;
  final bool hasReachedWeeklyCap;
  final bool isWide;
  final int completionPoints;
  final VoidCallback? onContinue;

  const _StageContent({
    required this.stage,
    required this.unit,
    required this.hasReachedWeeklyCap,
    required this.isWide,
    required this.completionPoints,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (unit == null || stage == LearningStage.completed) {
      return _CompletedStage(
        unit: unit,
        isWide: isWide,
        points: completionPoints,
        onContinue: onContinue,
      );
    }

    final card = _ActiveCard(
      stage: stage,
      unit: unit!,
      hasReachedWeeklyCap: hasReachedWeeklyCap,
    );
    final artHeight = switch (stage) {
      LearningStage.startActivity => 440.0,
      LearningStage.sendProject => 400.0,
      LearningStage.quizPending => 400.0,
      LearningStage.completed => 300.0,
    };

    if (!isWide) {
      return Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: card,
          ),
          const SizedBox(height: 22),
          HomeBuddyArt(stage: stage, maxHeight: 280),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final groupWidth = (constraints.maxWidth * 0.86).clamp(760.0, 920.0);
        final gap = (groupWidth * 0.05).clamp(28.0, 38.0);

        return Center(
          child: SizedBox(
            width: groupWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: card,
                    ),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: groupWidth * 0.3,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: HomeBuddyArt(stage: stage, maxHeight: artHeight),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompletedStage extends StatelessWidget {
  final CourseUnit? unit;
  final bool isWide;
  final int points;
  final VoidCallback? onContinue;

  const _CompletedStage({
    required this.unit,
    required this.isWide,
    required this.points,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final card = CompletedCard(
      points: points > 0 ? points : unit?.totalPoints ?? 0,
      onContinue: onContinue,
    );

    if (!isWide) {
      return Column(
        children: [
          HomeBuddyArt(stage: LearningStage.completed, maxHeight: 220),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: card,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Flexible(
          flex: 5,
          child: Align(
            alignment: Alignment.topRight,
            child: HomeBuddyArt(stage: LearningStage.completed, maxHeight: 270),
          ),
        ),
        const SizedBox(width: 36),
        Flexible(
          flex: 8,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: card,
          ),
        ),
        const SizedBox(width: 36),
        const Flexible(
          flex: 5,
          child: Align(
            alignment: Alignment.topLeft,
            child: HomeBuddyArt(stage: LearningStage.completed, maxHeight: 270),
          ),
        ),
      ],
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final LearningStage stage;
  final CourseUnit unit;
  final bool hasReachedWeeklyCap;

  const _ActiveCard({
    required this.stage,
    required this.unit,
    required this.hasReachedWeeklyCap,
  });

  @override
  Widget build(BuildContext context) {
    return switch (stage) {
      LearningStage.startActivity => StartActivityCard(
        courseDisplay: unit.courseDisplay,
        unitName: unit.unitName,
        thumbnailAsset: unit.thumbnailAsset,
        points: unit.videoPoints,
        onStart: hasReachedWeeklyCap
            ? null
            : () => context.go(AppRoutes.classroom),
      ),
      LearningStage.sendProject => SendProjectCard(
        courseDisplay: unit.courseDisplay,
        unitName: unit.unitName,
        points: unit.submissionPoints,
        onSend: () => context.go(AppRoutes.classroom),
      ),
      LearningStage.quizPending => QuizPendingCard(
        courseDisplay: unit.courseDisplay,
        unitName: unit.unitName,
        points: unit.totalPoints,
        onStartQuiz: () => context.go(AppRoutes.classroom),
      ),
      LearningStage.completed => CompletedCard(points: unit.totalPoints),
    };
  }
}
