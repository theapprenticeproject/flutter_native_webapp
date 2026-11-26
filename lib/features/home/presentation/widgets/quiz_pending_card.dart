import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import 'activity_card.dart';

/// The video and the work are done and the quiz is not.
class QuizPendingCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final String? thumbnailAsset;
  final VoidCallback onStartQuiz;

  const QuizPendingCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.onStartQuiz,
    this.thumbnailAsset,
  });

  @override
  Widget build(BuildContext context) {
    return ActivityCard(
      title: unitName,
      thumbnailAsset: thumbnailAsset,
      chip: ActivityChip(
        icon: Icons.assignment_outlined,
        text: context.l10n.homePendingQuiz,
      ),
      buttonLabel: context.l10n.homeStartQuiz,
      onPressed: onStartQuiz,
    );
  }
}
