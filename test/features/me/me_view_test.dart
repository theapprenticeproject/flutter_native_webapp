import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/me/level.dart';
import 'package:tapapp/domain/me/my_projects.dart';
import 'package:tapapp/domain/submission/feedback_state.dart';
import 'package:tapapp/features/me/presentation/me_view.dart';

/// R-7: Me has the profile, the level, the points, "My projects this year", the
/// skill chips (placeholders, R-95), settings and switch profile.
const _level = LevelProgress(
  id: 'bronze',
  name: 'Bronze Buddy',
  nextName: 'Silver Buddy',
  label: '120 / 400',
  fraction: 0.3,
  points: 120,
  nextMin: 400,
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
  int points = 120,
  String? subject = 'Science Lab',
  VoidCallback? onStart,
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
          points: points,
          subject: subject,
          level: level,
          onStartActivity: onStart ?? () {},
          projects: projects,
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
    // In the profile card ("My level") and in the level card.
    expect(find.text('Bronze Buddy'), findsNWidgets(2));
    expect(find.text('120 / 400 points'), findsOneWidget);
    expect(find.textContaining('Silver Buddy'), findsWidgets);
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

  testWidgets('has the placeholder skill chips (R-95, design M-ME-01)', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text("I'm getting better at"), findsOneWidget);
    expect(find.textContaining('Making new things'), findsOneWidget);
    expect(find.textContaining('Being on time'), findsOneWidget);
  });

  testWidgets(
    'with projects: the count, the one done and the one in progress',
    (tester) async {
      await _pump(
        tester,
        projects: [
          _p('Glowing LED Card', FeedbackStage.valid),
          _p('Paper Circuit', FeedbackStage.waiting),
          _p('Robot Hand', FeedbackStage.notSent),
          _p('Solar Car', FeedbackStage.notSent),
        ],
      );
      expect(find.text('My projects this year'), findsOneWidget);
      expect(find.text('1 / 4 done'), findsOneWidget);
      expect(find.text('Glowing LED Card'), findsOneWidget);
      expect(find.text('Feedback given'), findsOneWidget);
      expect(find.text('Paper Circuit'), findsOneWidget);
      expect(find.text('Feedback pending'), findsOneWidget);
      // The next ones are locked: no names yet (design M-ME-01).
      expect(find.text('Robot Hand'), findsNothing);
      expect(find.text('Project 3'), findsOneWidget);
    },
  );

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

  testWidgets('has the switch profile strip and a settings button', (
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

    await tester.tap(find.byTooltip('Settings'));
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

  // Design M-ME-01 and M-ME-02.
  group('the design', () {
    testWidgets('the welcome line and the settings button', (tester) async {
      await _pump(tester);
      expect(find.text('Welcome Asha 👋'), findsOneWidget);
      expect(find.text('Here is how you are doing this year'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('a new student: "Let\'s start your TAP journey"', (
      tester,
    ) async {
      await _pump(
        tester,
        points: 0,
        level: const LevelProgress(
          id: 'bronze',
          name: 'Bronze Buddy',
          nextName: 'Silver Buddy',
          label: '0 / 400',
          fraction: 0,
          points: 0,
          nextMin: 400,
        ),
      );
      expect(find.text("Let's start your TAP journey"), findsOneWidget);
      expect(
        find.text('Skills you get good at will show up here'),
        findsOneWidget,
      );
      expect(find.text('0 / 400 points'), findsOneWidget);
      expect(
        find.text('Finish your first activity to start earning points'),
        findsOneWidget,
      );
    });

    testWidgets('the profile card: initials, class, subject and school', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('A'), findsWidgets);
      expect(find.textContaining('Class 5'), findsOneWidget);
      expect(find.textContaining('Science Lab'), findsOneWidget);
      expect(find.text('My level'), findsOneWidget);
    });

    testWidgets('the level card: points left and Start Activity', (
      tester,
    ) async {
      var started = 0;
      await _pump(tester, onStart: () => started++);
      expect(find.text('Your level'), findsOneWidget);
      expect(
        find.text('280 more points to reach Silver Buddy'),
        findsOneWidget,
      );
      await tester.tap(find.text('Start Activity'));
      expect(started, 1);
    });

    testWidgets('the points card: the total and what points are', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Total points earned'), findsOneWidget);
      expect(find.text('What are points?'), findsOneWidget);
      expect(
        find.text('Earn points by doing TAP Activities every week!'),
        findsOneWidget,
      );
    });
  });
}
