import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import 'activity_card.dart';

/// The activity has not been started. The card has no chip: the points of an
/// activity (Figma "+40 points") are not known to the app yet.
class StartActivityCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final String thumbnailAsset;
  final VoidCallback? onStart;

  const StartActivityCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.thumbnailAsset,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return ActivityCard(
      title: unitName,
      thumbnailAsset: thumbnailAsset,
      buttonLabel: onStart == null
          ? context.l10n.homeWeeklyLimit
          : context.l10n.homeStartActivity,
      onPressed: onStart,
    );
  }
}
