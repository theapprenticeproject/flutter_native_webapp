import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/models/class_chat_message_model.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_chat_row.dart';

/// The upload card has no TAP Buddy avatar beside it: the avatar showed at the
/// bottom left of the tall card, under "I'll do it later" (design M-S-01).
ClassChatMessage _m(ClassChatContentType type) => ClassChatMessage(
  id: '1',
  stepId: 'x',
  sender: ClassChatSender.bot,
  contentType: type,
);

void main() {
  test('a bubble keeps its avatar', () {
    expect(showsBotAvatar(_m(ClassChatContentType.text)), isTrue);
  });

  test('the upload card and the quiz question have no avatar', () {
    expect(showsBotAvatar(_m(ClassChatContentType.submission)), isFalse);
    expect(showsBotAvatar(_m(ClassChatContentType.quizQuestion)), isFalse);
  });
}
