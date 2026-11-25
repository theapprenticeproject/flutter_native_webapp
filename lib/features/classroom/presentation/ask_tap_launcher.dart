import 'package:flutter/material.dart';

import '../../../shared/ask_tap/ask_tap_sheet.dart';
import '../providers/class_chat_controller.dart';

/// Opens Ask TAP from the activity (the header button and "Need help?"). The AI
/// is told the unit and the step.
void openAskTapFor(BuildContext context, ClassChatController controller) {
  final step = controller.stepBar.current;
  showAskTapSheet(
    context,
    studentName: controller.studentName,
    screen: 'activity',
    extra: {'unit_name': controller.unitName, 'step': ?step?.name},
    fromActivity: true,
  );
}
