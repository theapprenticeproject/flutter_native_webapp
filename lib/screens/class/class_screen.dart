import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/class_chat_message_model.dart';
import '../../providers/class_chat_controller.dart';
import '../../providers/class_chat_provider.dart';
import '../../providers/class_session_bootstrap_provider.dart';
import '../../providers/home_dashboard_provider.dart';
import '../../providers/learner_state_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_nav.dart';
import 'widgets/class_chat_row.dart';
import 'widgets/class_loading_skeleton.dart';
import 'widgets/class_message_content.dart';
import 'widgets/class_reveal_widgets.dart';

class ClassScreen extends ConsumerStatefulWidget {
  const ClassScreen({super.key});

  @override
  ConsumerState<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends ConsumerState<ClassScreen> {
  int _attempt = 0;

  Future<void> _startNextActivity() async {
    final profile = await ref.read(activeProfileProvider.future);
    if (profile == null) return;
    final repository = await ref.read(learnerStateRepositoryProvider.future);
    await repository.clearHomeCelebration(profile.learnerId);
    ref.invalidate(learningDashboardProvider);
    ref.invalidate(classSessionBootstrapProvider);
    if (!mounted) return;
    setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(learningDashboardProvider);

    return dashboardAsync.when(
      loading: () => _scaffold(const ClassLoadingSkeleton()),
      error: (_, _) => _buildClassSession(),
      data: (dashboard) {
        if (dashboard.hasReachedWeeklyCap) {
          return _scaffold(
            ClassWeeklyCapRevealBody(
              unitIndex: 0,
              onHome: () => context.go(AppRoutes.home),
            ),
          );
        }
        if (dashboard.showCompletionCelebration && dashboard.unit != null) {
          return _scaffold(
            ClassPendingActivityChoiceBody(
              unit: dashboard.unit!,
              onStart: _startNextActivity,
              onMaybeLater: () => context.go(AppRoutes.home),
            ),
          );
        }
        return _buildClassSession();
      },
    );
  }

  Widget _buildClassSession() {
    final controllerAsync = ref.watch(classChatControllerProvider(_attempt));

    return _scaffold(
      controllerAsync.when(
        loading: () => const ClassLoadingSkeleton(),
        error: (error, _) {
          if (error is NoUnitAvailableException) {
            return ClassWeeklyCapRevealBody(
              unitIndex: 0,
              onHome: () => context.go(AppRoutes.home),
            );
          }
          return _ErrorBody(
            error: error,
            onBack: () => context.go(AppRoutes.home),
          );
        },
        data: (controller) => _ClassChatView(
          controller: controller,
          onStartNextActivity: _startNextActivity,
        ),
      ),
    );
  }

  Widget _scaffold(Widget body) => AppNav(
        child: Scaffold(backgroundColor: AppTheme.appBackground, body: body),
      );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onBack});

  final Object error;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isNoEnrollment = error is NoActiveEnrollmentException;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNoEnrollment
                  ? "You're not enrolled in a course yet."
                  : 'Something went wrong loading your class.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassChatView extends ConsumerStatefulWidget {
  const _ClassChatView({
    required this.controller,
    required this.onStartNextActivity,
  });

  final ClassChatController controller;
  final VoidCallback onStartNextActivity;

  @override
  ConsumerState<_ClassChatView> createState() => _ClassChatViewState();
}

class _ClassChatViewState extends ConsumerState<_ClassChatView> {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  int _lastQuizToastId = 0;
  OverlayEntry? _quizToastOverlay;
  Timer? _quizToastTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _ClassChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _lastMessageCount = 0;
      _lastQuizToastId = 0;
      _removeQuizToast();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _removeQuizToast();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final quizToast = widget.controller.quizToast;
    if (quizToast != null && quizToast.id != _lastQuizToastId) {
      _lastQuizToastId = quizToast.id;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showQuizToast(quizToast),
      );
    }
    if (widget.controller.messages.length != _lastMessageCount) {
      _lastMessageCount = widget.controller.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _showQuizToast(ClassQuizToast toast) {
    if (!mounted) return;
    _removeQuizToast();

    final media = MediaQuery.of(context);
    final isWide = media.size.width >= 640;
    _quizToastOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: media.padding.top + (isWide ? 96 : 12),
        right: isWide ? 24 : 12,
        left: isWide ? null : 12,
        width: isWide ? 320 : null,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: toast.isCorrect
                    ? const Color(0xFFDCF6E7)
                    : const Color(0xFFFFE7E2),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    toast.isCorrect ? '🎉' : '💡',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      toast.isCorrect
                          ? 'Correct Answer!  +${toast.points} points'
                          : 'Not quite. Correct answer: ${toast.correctAnswer ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF25252B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_quizToastOverlay!);
    _quizToastTimer = Timer(
      Duration(milliseconds: toast.isCorrect ? 1400 : 2300),
      _removeQuizToast,
    );
  }

  void _removeQuizToast() {
    _quizToastTimer?.cancel();
    _quizToastTimer = null;
    _quizToastOverlay?.remove();
    _quizToastOverlay = null;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.outcome == ClassSessionOutcome.weeklyCapReached) {
          return ClassWeeklyCapRevealBody(
            unitIndex: widget.controller.unitIndex,
            onHome: () => context.go(AppRoutes.home),
          );
        }

        final showChoiceReveal =
            widget.controller.outcome == ClassSessionOutcome.choice;
        final isVideoStartCheckpoint =
            widget.controller.messages.length == 1 &&
            widget.controller.messages.first.contentType ==
                ClassChatContentType.checkpoint &&
            widget.controller.messages.first.data['action'] == 'video';

        return Column(
          children: [
            AppHeader(
              title: widget.controller.unitName,
              points: widget.controller.displayedTotalPoints,
              showBack: true,
              showPoints: true,
              showAskBuddy: true,
              onBack: () => context.go(AppRoutes.home),
            ),
            Expanded(
              child: Container(
                color: AppTheme.appBackground,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showRail = constraints.maxWidth >= 640;

                    if (isVideoStartCheckpoint) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1060),
                          child: ClassCheckpointCard(
                            message: widget.controller.messages.first,
                            controller: widget.controller,
                            fillAvailableHeight: true,
                          ),
                        ),
                      );
                    }

                    final chatColumn = ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
                      itemCount:
                          widget.controller.messages.length +
                          (showChoiceReveal ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < widget.controller.messages.length) {
                          final message = widget.controller.messages[index];
                          return ClassChatBubbleRow(
                            key: ValueKey(message.id),
                            message: message,
                            controller: widget.controller,
                          );
                        }
                        return ClassNextActivityInlineCard(
                          controller: widget.controller,
                          onStartNextActivity: widget.onStartNextActivity,
                        );
                      },
                    );

                    if (!showRail) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Container(
                            color: AppTheme.classroomBackground,
                            child: chatColumn,
                          ),
                        ),
                      );
                    }

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1060),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  60,
                                  14,
                                  0,
                                  14,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 700,
                                  ),
                                  child: Container(
                                    color: AppTheme.classroomBackground,
                                    child: chatColumn,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 260,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  34,
                                  20,
                                  16,
                                  20,
                                ),
                                child: ClassRevealRail(
                                  unitIndex: widget.controller.unitIndex,
                                  revealProgress: showChoiceReveal
                                      ? 1
                                      : widget.controller.revealProgress,
                                  studentName: widget.controller.studentName,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (widget.controller.isAwaitingContinue && !showChoiceReveal)
              ClassContinueBar(
                onContinue: widget.controller.continueAfterReview,
              ),
          ],
        );
      },
    );
  }
}
