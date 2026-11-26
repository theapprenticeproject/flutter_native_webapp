import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/core/constants/build_info.dart';
import 'package:tapapp/features/auth/presentation/open_link_screen.dart';
import 'package:tapapp/features/me/presentation/me_view.dart';
import 'package:tapapp/shared/widgets/build_info_toggle.dart';

/// Before a deploy, the tester must read which commit, which Flutter and which
/// Worker a build uses. The line was shown on the old login screen, which is
/// gone. It must stay reachable: long-press the logo.
void main() {
  testWidgets('a long press shows the build line, another hides it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: BuildInfoToggle(child: Text('TAP'))),
        ),
      ),
    );
    expect(find.textContaining('Build '), findsNothing);

    await tester.longPress(find.text('TAP'));
    await tester.pump();
    expect(find.text(BuildInfo.label), findsOneWidget);
    expect(find.textContaining('API '), findsOneWidget);

    await tester.longPress(find.text('TAP'));
    await tester.pump();
    expect(find.textContaining('Build '), findsNothing);
  });

  testWidgets('the open-link page has it (a student with no sign-in)', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OpenLinkScreen()));
    await tester.pump();
    await tester.longPress(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pump();
    expect(find.text(BuildInfo.label), findsOneWidget);
  });

  testWidgets('the Me page has it (a signed-in student)', (tester) async {
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeView(
            studentName: 'Asha',
            grade: '5',
            school: null,
            points: 1,
            level: null,
            projects: const [],
            onSwitchProfile: () {},
            onSettings: () {},
            onOpenProject: (_) {},
            onStartActivity: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(find.text('TAP'), 300);
    await tester.longPress(find.text('TAP'));
    await tester.pump();
    expect(find.text(BuildInfo.label), findsOneWidget);
  });

  test('the build line is used by a screen, not only defined', () {
    final users = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('build_info.dart')) continue;
      if (f.readAsStringSync().contains('BuildInfo')) users.add(f.path);
    }
    expect(users, isNotEmpty);
  });
}
