import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/me/my_projects.dart';
import 'package:tapapp/domain/submission/feedback_state.dart';
import 'package:tapapp/features/me/presentation/project_journey.dart';
import 'package:tapapp/features/me/presentation/project_page.dart';
import 'package:tapapp/features/me/presentation/project_sheet.dart';

/// Design M-ME-01: the project path, the bottom sheet and the project page.
MyProject _p(
  String name,
  FeedbackStage stage, {
  String? feedback,
  DateTime? at,
  String? url,
}) => MyProject(
  unitName: name,
  assignmentId: 'AS-$name',
  stage: stage,
  feedback: feedback,
  createdAt: at,
  viewUrl: url,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}

/// A full page has its own scrolling: it is shown as it is.
Future<void> _pumpPage(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}

void main() {
  group('the path', () {
    final projects = [
      _p('Paper Circuit', FeedbackStage.valid),
      _p('Robot Hand', FeedbackStage.waiting),
      _p('Solar Car', FeedbackStage.notSent),
      _p('Art from Waste', FeedbackStage.notSent),
    ];

    testWidgets('title, count, hint, and each kind of node', (tester) async {
      await _pump(
        tester,
        ProjectJourney(
          projects: projects,
          studentName: 'Aarav Kumar',
          onOpen: (_) {},
          onStart: () {},
        ),
      );
      expect(find.text('My projects this year'), findsOneWidget);
      expect(find.text('1 / 4 done'), findsOneWidget);
      expect(
        find.text('Tap a project to see your work and feedback 👆'),
        findsOneWidget,
      );
      expect(find.text('Paper Circuit'), findsOneWidget); // done
      expect(find.text('Feedback given'), findsOneWidget);
      expect(find.text('Robot Hand'), findsOneWidget); // current
      expect(find.text('Feedback pending'), findsOneWidget);
      expect(find.text('You are here'), findsOneWidget);
      // The ones after it are locked: only "Project 3", no name.
      expect(find.text('Project 3'), findsOneWidget);
      expect(find.text('Project 4'), findsOneWidget);
      expect(find.text('Unlocks soon'), findsNWidgets(2));
      expect(find.text('Solar Car'), findsNothing);
    });

    testWidgets('tapping a done project, or the current one, opens it', (
      tester,
    ) async {
      final opened = <String>[];
      await _pump(
        tester,
        ProjectJourney(
          projects: projects,
          studentName: 'Aarav Kumar',
          onOpen: (p) => opened.add(p.unitName),
          onStart: () {},
        ),
      );
      await tester.tap(find.text('Paper Circuit'));
      await tester.tap(find.text('Robot Hand'));
      expect(opened, ['Paper Circuit', 'Robot Hand']);
    });

    testWidgets('a locked project cannot be opened', (tester) async {
      final opened = <String>[];
      await _pump(
        tester,
        ProjectJourney(
          projects: projects,
          studentName: 'Aarav Kumar',
          onOpen: (p) => opened.add(p.unitName),
          onStart: () {},
        ),
      );
      await tester.tap(find.text('Project 3'));
      expect(opened, isEmpty);
    });

    testWidgets('the next project not started: "Up next" and Start Activity', (
      tester,
    ) async {
      var started = 0;
      await _pump(
        tester,
        ProjectJourney(
          projects: [
            _p('Paper Circuit', FeedbackStage.valid),
            _p('Art from Waste', FeedbackStage.notSent),
            _p('Solar Car', FeedbackStage.notSent),
          ],
          studentName: 'Aarav Kumar',
          onOpen: (_) {},
          onStart: () => started++,
        ),
      );
      expect(find.text('Up next'), findsOneWidget);
      await tester.tap(find.text('Start Activity'));
      expect(started, 1);
    });

    testWidgets('no projects: a friendly line, no count', (tester) async {
      await _pump(
        tester,
        ProjectJourney(
          projects: const [],
          studentName: 'Aarav Kumar',
          onOpen: (_) {},
          onStart: () {},
        ),
      );
      expect(find.textContaining('No projects yet'), findsOneWidget);
      expect(find.textContaining('done'), findsNothing);
    });
  });

  group('the project page', () {
    testWidgets(
      'feedback given: the chip, the date and what TAP Buddy thinks',
      (tester) async {
        await _pumpPage(
          tester,
          ProjectPage(
            project: _p(
              'Smart Budget',
              FeedbackStage.valid,
              feedback: 'Your budget adds up.',
              at: DateTime(2026, 9, 5, 18, 10),
            ),
            onSendAgain: () {},
          ),
        );
        expect(find.text('Smart Budget'), findsOneWidget);
        expect(find.text('Feedback given'), findsOneWidget);
        expect(find.textContaining('Shared 5 Sep'), findsOneWidget);
        expect(find.text('TAP Buddy thinks'), findsOneWidget);
        expect(find.text('Your budget adds up.'), findsOneWidget);
        expect(find.text('Send again'), findsNothing);
      },
    );

    testWidgets('waiting: TAP Buddy is still looking', (tester) async {
      await _pumpPage(
        tester,
        ProjectPage(
          project: _p('Get Ready', FeedbackStage.waiting),
          onSendAgain: () {},
        ),
      );
      expect(find.text('Feedback pending'), findsOneWidget);
      expect(
        find.text(
          "I'm still looking at your work. I'll share what I think very soon!",
        ),
        findsOneWidget,
      );
    });

    testWidgets('not valid: the warning and Send again, as often as needed', (
      tester,
    ) async {
      var again = 0;
      await _pumpPage(
        tester,
        ProjectPage(
          project: _p(
            'Art from Waste',
            FeedbackStage.notValid,
            feedback: 'This photo does not show the activity.',
          ),
          onSendAgain: () => again++,
        ),
      );
      expect(find.text('Wrong format'), findsOneWidget);
      expect(find.textContaining('do better next time'), findsOneWidget);
      await tester.tap(find.text('Send again'));
      expect(again, 1);
    });
  });

  testWidgets('the bottom sheet: the name, the state and See my work', (
    tester,
  ) async {
    var seen = 0;
    await _pump(
      tester,
      ProjectSheet(
        project: _p('Get Ready For ScratchJr', FeedbackStage.waiting),
        onSeeWork: () => seen++,
        onClose: () {},
      ),
    );
    expect(find.text('Get Ready For ScratchJr'), findsOneWidget);
    expect(find.text('Feedback pending'), findsOneWidget);
    await tester.tap(find.text('See my work'));
    expect(seen, 1);
  });
}
