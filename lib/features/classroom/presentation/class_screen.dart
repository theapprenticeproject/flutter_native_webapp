import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'ask_tap_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../models/class_chat_message_model.dart';
import '../providers/class_chat_controller.dart';
import '../providers/class_chat_provider.dart';
import '../../../domain/learning_progress/class_session_bootstrap_provider.dart';
import '../../../domain/learning_progress/home_dashboard_provider.dart';
import '../../../domain/learner/learner_state_provider.dart';
import '../../../domain/profile/profile_provider.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_nav.dart';
import '../../../shared/widgets/load_error_view.dart';
import 'widgets/activity_step_bar.dart';
import 'widgets/class_chat_row.dart';
import 'widgets/class_loading_skeleton.dart';
import 'widgets/class_message_content.dart';
import 'widgets/class_reveal_widgets.dart';
import '../../../domain/learning_progress/picture_pieces.dart';
import '../../../domain/learning_progress/watch_navigation.dart';
import '../../../domain/progress/app_config_provider.dart';
import 'widgets/picture_badge.dart';

class ClassScreen extends ConsumerStatefulWidget {
  const ClassScreen({super.key, this.videoOpen = false});

  /// The address says the video is open (`/classroom?step=video`).
  final bool videoOpen;

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
            return ClassNoActivityBody(
              unitIndex: 0,
              onHome: () => context.go(AppRoutes.home),
            );
          }
          return LoadErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(classSessionBootstrapProvider);
              ref.invalidate(classChatControllerProvider(_attempt));
            },
          );
        },
        data: (controller) => _ClassChatView(
          controller: controller,
          onStartNextActivity: _startNextActivity,
          videoOpen: widget.videoOpen,
        ),
      ),
    );
  }

  Widget _scaffold(Widget body) => AppNav(
    child: Scaffold(backgroundColor: AppTheme.appBackground, body: body),
  );
}

class _ClassChatView extends ConsumerStatefulWidget {
  const _ClassChatView({
    required this.controller,
    required this.onStartNextActivity,
    required this.videoOpen,
  });

  final ClassChatController controller;
  final VoidCallback onStartNextActivity;
  final bool videoOpen;

  @override
  ConsumerState<_ClassChatView> createState() => _ClassChatViewState();
}

class _ClassChatViewState extends ConsumerState<_ClassChatView> {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  bool _videoUrlCleared = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    // A new page load at the video address (a reload, a pasted link) starts at
    // the Watch start screen, so the address goes back to match.
    if (widget.videoOpen) _clearVideoUrl();
  }

  /// Replaces `/classroom?step=video` by `/classroom` in the history, so Back
  /// leaves the activity instead of stepping to a screen that no longer exists.
  void _clearVideoUrl() {
    if (_videoUrlCleared) return;
    _videoUrlCleared = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.replace(AppRoutes.classroom);
    });
  }

  @override
  void didUpdateWidget(covariant _ClassChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    switch (watchNavFor(
      wasOpen: oldWidget.videoOpen,
      isOpen: widget.videoOpen,
      watched: widget.controller.videoWatched,
    )) {
      case WatchNav.open:
        _videoUrlCleared = false;
        widget.controller.openVideo();
      case WatchNav.backToStart:
        widget.controller.backToStart();
      case WatchNav.none:
        break;
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _lastMessageCount = 0;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _openPicture() => showRevealSheet(
    context,
    unitIndex: widget.controller.unitIndex,
    pieces: widget.controller.unlockedPictureCount,
  );

  void _onControllerChanged() {
    // The student tapped "I watched it": the video step is saved and cannot be
    // undone, so the video address is replaced. Back then leaves the activity.
    if (widget.videoOpen && widget.controller.videoWatched) _clearVideoUrl();
    final narrow = MediaQuery.sizeOf(context).width < 640;
    final due = widget.controller.takeRevealSheetDue();
    if (shouldShowRevealSheet(due: due, narrow: narrow)) {
      Future<void>.delayed(revealSheetDelay, () {
        if (mounted) _openPicture();
      });
    }

    if (widget.controller.outcome == ClassSessionOutcome.leave) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
    }
    if (widget.controller.messages.length != _lastMessageCount) {
      _lastMessageCount = widget.controller.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      // A picture decodes and a card grows a little after the message appears.
      // Scroll again, so the last card does not stay under the 2/4 badge (QA 14).
      for (final ms in const [250, 700]) {
        Future<void>.delayed(Duration(milliseconds: ms), () {
          if (mounted) _scrollToBottom();
        });
      }
    }
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
        final showChoiceReveal =
            widget.controller.outcome == ClassSessionOutcome.choice;
        final isVideoStartCheckpoint =
            widget.controller.messages.length == 1 &&
            widget.controller.messages.first.contentType ==
                ClassChatContentType.checkpoint &&
            widget.controller.messages.first.data['action'] == 'video';

        final activityPoints = ref
            .watch(appConfigProvider)
            .valueOrNull
            ?.rules
            .activityPoints(quizQuestions: widget.controller.quizQuestionCount);

        // The badge floats at the bottom right (design M-C03, M-C05).
        return Stack(
          children: [
            Column(
              children: [
                // Design M-C01: the start screen has the activity name and no
                // points. Design M-C03: the later screens have the points and
                // the step bar, and no name.
                AppHeader(
                  title: isVideoStartCheckpoint
                      ? widget.controller.unitName
                      : '',
                  // The pill shows what THIS activity can earn (design M-C03),
                  // from the server's point rules. Without them, the total.
                  pointsAreActivity: activityPoints != null,
                  points:
                      activityPoints ?? widget.controller.displayedTotalPoints,
                  showBack: true,
                  showPoints: !isVideoStartCheckpoint,
                  onBack: () => context.go(AppRoutes.home),
                  onAskTap: () => openAskTapFor(context, widget.controller),
                ),
                if (!isVideoStartCheckpoint)
                  ActivityStepBar(state: widget.controller.stepBar),
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
                          padding: const EdgeInsets.fromLTRB(
                            14,
                            20,
                            14,
                            PictureBadge.clearance,
                          ),
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
                                      studentName:
                                          widget.controller.studentName,
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
            ),
            Positioned(
              right: PictureBadge.margin,
              bottom: PictureBadge.margin,
              child: PictureBadge(
                pieces: widget.controller.unlockedPictureCount,
                unitIndex: widget.controller.unitIndex,
                onTap: _openPicture,
              ),
            ),
          ],
        );
      },
    );
  }
}
