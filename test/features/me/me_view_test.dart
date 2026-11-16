import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/me/level.dart';
import 'package:tapapp/domain/me/my_projects.dart';
import 'package:tapapp/domain/submission/feedback_state.dart';
import 'package:tapapp/features/me/presentation/me_view.dart';
import 'package:tapapp/features/me/skill_tags.dart';

/// R-7: Me has the profile, the level, the points, "My projects this year", the
/// skill chips (placeholders, R-95), settings and switch profile.
const _level = LevelProgress(
  name: 'Bronze Buddy',
  nextName: 'Silver Buddy',
  label: '120 / 1000',
  fraction: 0.12,
);

MyProject _p(String name, FeedbackStage stage, {String? feedback}) => MyProject(
  unitName: name,
  assignmentId: 'AS-$name',
  stage: stage,
  feedback: feedback,
);

Future<void> _pump(
  WidgetTester tester, {
  List<MyProject> projects = const [],
  LevelProgress? level = _level,
  VoidCallback? onSwitch,
  VoidCallback? onSettings,
  void Function(MyProject)? onOpen,
}) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MeView(
          studentName: 'Asha',
          grade: '5',
          school: 'New Horizon Public School',
          points: 120,
          level: level,
          projects: projects,
          tags: skillTags,
          onSwitchProfile: onSwitch ?? () {},
          onSettings: onSettings ?? () {},
          onOpenProject: onOpen ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'shows the profile: name, class and school, no photo of the child',
    (tester) async {
      await _pump(tester);
      expect(find.text('Asha'), findsWidgets);
      expect(find.textContaining('Class 5'), findsOneWidget);
      expect(find.textContaining('New Horizon Public School'), findsOneWidget);
      // R-60: the TAP Buddy picture is used, never a photo of the student.
      expect(find.byType(Image), findsWidgets);
    },
  );

  testWidgets('shows the level, its progress and the points', (tester) async {
    await _pump(tester);
    expect(find.text('Bronze Buddy'), findsOneWidget);
    expect(find.text('120 / 1000'), findsOneWidget);
    expect(find.textContaining('Silver Buddy'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('120'), findsWidgets);
  });

  testWidgets('no level (the Worker was not reached): the points still show', (
    tester,
  ) async {
    await _pump(tester, level: null);
    expect(find.text('Bronze Buddy'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('120'), findsWidgets);
  });

  testWidgets('shows the placeholder skill chips', (tester) async {
    await _pump(tester);
    expect(find.text("I'm getting better at"), findsOneWidget);
    for (final tag in skillTags) {
      expect(find.text(tag), findsOneWidget, reason: tag);
    }
  });

  testWidgets('with projects: the count and each state', (tester) async {
    await _pump(
      tester,
      projects: [
        _p('Glowing LED Card', FeedbackStage.valid),
        _p('Paper Circuit', FeedbackStage.waiting),
        _p('Robot Hand', FeedbackStage.notValid),
        _p('Solar Car', FeedbackStage.notSent),
      ],
    );
    expect(find.text('My projects this year'), findsOneWidget);
    expect(find.text('1 / 4 done'), findsOneWidget);
    expect(find.text('Glowing LED Card'), findsOneWidget);
    expect(find.text('Feedback given'), findsOneWidget);
    expect(find.text('Feedback pending'), findsOneWidget);
    expect(find.text('Wrong format'), findsOneWidget);
    expect(find.text('Not started'), findsOneWidget);
  });

  testWidgets('without projects: a friendly empty state', (tester) async {
    await _pump(tester);
    expect(find.text('My projects this year'), findsOneWidget);
    expect(find.textContaining('No projects yet'), findsOneWidget);
    expect(find.textContaining('done'), findsNothing);
  });

  testWidgets('tapping a project opens it', (tester) async {
    MyProject? opened;
    await _pump(
      tester,
      projects: [_p('Glowing LED Card', FeedbackStage.valid)],
      onOpen: (p) => opened = p,
    );
    await tester.tap(find.text('Glowing LED Card'));
    expect(opened?.unitName, 'Glowing LED Card');
  });

  testWidgets('has the switch profile strip and a settings row', (
    tester,
  ) async {
    var switched = 0;
    var settings = 0;
    await _pump(
      tester,
      onSwitch: () => switched++,
      onSettings: () => settings++,
    );

    expect(find.textContaining('Not Asha?'), findsOneWidget);
    await tester.tap(find.text('Switch Profile'));
    expect(switched, 1);

    await tester.tap(find.text('Settings'));
    expect(settings, 1);
  });

  testWidgets('has no Edit profile, no Sign out and no theme switch in v1', (
    tester,
  ) async {
    await _pump(tester);
    for (final word in [
      'Edit profile',
      'Sign out',
      'Log out',
      'Theme',
      'Dark',
    ]) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });
}
