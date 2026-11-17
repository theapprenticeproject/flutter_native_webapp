import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_section_checkpoint.dart';

/// R-17: messages never play by themselves, and a speaker icon plays a clip
/// when the student taps it (task D15). Until D15 there is no audio, so the app
/// must not say "TAP Buddy is speaking" or offer "Hear again". A student would
/// wait for a sound that never comes.
void main() {
  testWidgets('TAP Buddy does not say it is speaking and does not pulse', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ClassTapBuddyOrb())),
      ),
    );
    await tester.pump();

    expect(find.text('TAP Buddy'), findsOneWidget);
    expect(find.text('Speaking'), findsNothing);
    expect(
      tester.hasRunningAnimations,
      isFalse,
      reason: 'a pulse looks like speaking',
    );
  });

  testWidgets('the checkpoint has no "Hear again" button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClassSectionCheckpoint(
              kind: ClassSectionCheckpointKind.quiz,
              text: 'Let us start the quiz',
              buttonLabel: 'Quiz',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Hear again'), findsNothing);
    expect(find.text('Let us start the quiz'), findsOneWidget);
  });

  test('no screen in lib/ shows "Speaking" or "Hear again" before D15', () {
    final found = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      if (text.contains("'Speaking'") || text.contains("'Hear again'")) {
        found.add(f.path);
      }
    }
    expect(found, isEmpty);
  });

  test('the class screens have no speaker icon that does nothing (R-54)', () {
    final found = <String>[];
    for (final f in Directory(
      'lib/features/classroom',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.readAsStringSync().contains('volume_up')) found.add(f.path);
    }
    expect(found, isEmpty, reason: 'D15 adds the real speaker icon');
  });
}
