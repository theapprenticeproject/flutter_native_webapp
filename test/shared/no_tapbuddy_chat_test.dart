import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M0 / D0: the prototype TapBuddy AI chat and its Ask TAP panel are gone.
/// In v1, Ask TAP shows prepared questions only (R-70). It comes back later as
/// a new panel (D10), so the old chat code must not return.
///
/// The animated TAP Buddy character in the classroom (`ClassTapBuddySpeakingOrb`)
/// is not the AI chat, so it is not on this list.
final _tapBuddyChatPieces = <String, RegExp>{
  'the chat folder lib/domain/tapbuddy': RegExp(r'domain/tapbuddy'),
  'the chat repository or provider': RegExp(r'tapbuddy_chat'),
  'the chat turn model': RegExp(r'ChatTurnModel|chat_turn_model'),
  'the context provider': RegExp(
    r'tap_buddy_context_provider|tapBuddyContextProvider|TapBuddyContext',
  ),
  'the Ask TAP panel': RegExp(r'TapBuddyPanel|tap_buddy_panel'),
  'the panel scope': RegExp(r'TapBuddyScope'),
  'the chat endpoint': RegExp(r'/tapbuddy/chat|tapbuddyChat'),
  'the chat history cache key': RegExp(r'chatTranscript'),
  'the Ask TAP button in the header': RegExp(
    r'showAskBuddy|onAskBuddy|AskBuddyButton',
  ),
};

void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (final entry in _tapBuddyChatPieces.entries) {
    test('lib/ has no ${entry.key}', () {
      final found = <String>[];
      for (final file in dartFiles) {
        if (entry.value.hasMatch(file.path) ||
            entry.value.hasMatch(file.readAsStringSync())) {
          found.add(file.path);
        }
      }
      expect(found, isEmpty, reason: 'Still found in: $found');
    });
  }
}
