import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/profile/student_language_provider.dart';
import 'package:tapapp/domain/tap_buddy/tap_buddy_provider.dart';
import 'package:tapapp/domain/tap_buddy/tap_buddy_repository.dart';
import 'package:tapapp/shared/ask_tap/ask_tap_sheet.dart';

class _FakeRepo implements TapBuddyRepository {
  final asked = <(String, Map<String, Object?>)>[];

  @override
  Future<String> ask(
    String message, {
    required Map<String, Object?> context,
  }) async {
    asked.add((message, context));
    return 'Tap Add my work.';
  }
}

Future<_FakeRepo> _pump(
  WidgetTester tester, {
  bool fromActivity = false,
}) async {
  tester.view.physicalSize = const Size(500, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  final repo = _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tapBuddyRepositoryProvider.overrideWithValue(repo),
        studentLanguageProvider.overrideWithValue('hi'),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AskTapSheet(
            studentName: 'Aarav Kumar',
            screen: 'activity',
            extra: const {'step': 'make'},
            fromActivity: fromActivity,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return repo;
}

/// Design M-S-06, M-D-01 and M-D-02. The chat is free: no prepared questions.
void main() {
  testWidgets('opens with a greeting and a text box, no prepared questions', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('TAP Buddy'), findsOneWidget);
    expect(find.text('Hey there Aarav!\nHow may I help you?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('click the button'), findsNothing);
  });

  testWidgets('a typed question is sent with the language and the step', (
    tester,
  ) async {
    final repo = await _pump(tester, fromActivity: true);
    await tester.enterText(find.byType(TextField), 'Photo kaise bhejte hain?');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump();
    expect(repo.asked.single.$1, 'Photo kaise bhejte hain?');
    expect(repo.asked.single.$2, {
      'screen': 'activity',
      'language': 'hi',
      'step': 'make',
    });
    expect(find.text('Photo kaise bhejte hain?'), findsOneWidget);
    expect(find.text('Tap Add my work.'), findsOneWidget);
    expect(find.text('Back to my activity'), findsOneWidget);
  });

  testWidgets('opened from Home: no "Back to my activity"', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'What is a sprite?');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump();
    expect(find.text('Back to my activity'), findsNothing);
  });
}
