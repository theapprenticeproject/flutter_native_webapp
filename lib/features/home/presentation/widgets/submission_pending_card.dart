import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/learning_progress/home_dashboard_provider.dart';
import 'activity_card.dart';

/// The work is sent and the student waits for feedback (R-4, R-68). There is
/// nothing to do, so the card has only "Check again", which asks the Worker.
class SubmissionPendingCard extends ConsumerWidget {
  const SubmissionPendingCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.slow,
    this.ready = false,
    this.onOpen,
    this.thumbnailAsset,
  });

  final String courseDisplay;
  final String unitName;

  /// Feedback is taking longer than expected (24 hours, A13).
  final bool slow;

  /// The feedback is valid and waiting to be seen (R-68): the button opens it.
  final bool ready;
  final VoidCallback? onOpen;
  final String? thumbnailAsset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return ActivityCard(
      title: unitName,
      thumbnailAsset: thumbnailAsset,
      chip: ActivityChip(
        icon: ready
            ? Icons.check_circle_outline_rounded
            : Icons.schedule_rounded,
        text: ready ? l.homeFeedbackReady : l.homePendingFeedback,
      ),
      body: ready
          ? l.homeFeedbackReadyText
          : slow
          ? l.homeFeedbackSlowText
          : l.homeFeedbackWaitingText,
      buttonLabel: ready ? l.homeSeeFeedback : l.homeCheckAgain,
      onPressed: ready
          ? onOpen
          : () => ref.invalidate(learningDashboardProvider),
    );
  }
}
