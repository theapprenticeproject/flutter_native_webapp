import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import 'activity_card.dart';

/// The video and the quiz are done and there is no work yet (R-4, R-66).
class SendProjectCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final String? thumbnailAsset;
  final VoidCallback onSend;

  const SendProjectCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.onSend,
    this.thumbnailAsset,
  });

  @override
  Widget build(BuildContext context) {
    return ActivityCard(
      title: unitName,
      thumbnailAsset: thumbnailAsset,
      chip: ActivityChip(
        icon: Icons.info_outline_rounded,
        text: context.l10n.homeToDoSend,
      ),
      buttonLabel: context.l10n.homeSendProject,
      onPressed: onSend,
    );
  }
}
