import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/app_header.dart' show ActivityPointsCoin;
import 'activity_card.dart';

/// The activity has not been started: the thumbnail, the title, the points when
/// they are known (Figma "+40 points", M-F2-01) and "Start Activity".
class StartActivityCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final String thumbnailAsset;
  final VoidCallback? onStart;

  /// The points of the activity, when the server tells them. Without them the
  /// card shows no chip (the number is not made up).
  final int? points;

  const StartActivityCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.thumbnailAsset,
    required this.onStart,
    this.points,
  });

  @override
  Widget build(BuildContext context) {
    return ActivityCard(
      title: unitName,
      thumbnailAsset: thumbnailAsset,
      chip: points == null
          ? null
          : ActivityChip(
              leading: const ActivityPointsCoin(size: 16),
              text: context.l10n.homePointsPill(points!),
            ),
      buttonLabel: onStart == null
          ? context.l10n.homeWeeklyLimit
          : context.l10n.homeStartActivity,
      onPressed: onStart,
    );
  }
}
