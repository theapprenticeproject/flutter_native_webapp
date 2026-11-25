import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/models/activity_step.dart';
import 'package:tapapp/features/classroom/presentation/widgets/activity_step_bar.dart';

/// QA bugs 8, 12 and 16: the design shows a step bar under the header on every
/// screen of the activity: 1 Watch, 2 Make, 3 Quiz, 4 Results. A finished step
/// has a check, the current one is filled, the others are grey.
ActivityStepBarState _bar({
  bool video = false,
  bool work = false,
  bool quiz = false,
  bool results = false,
  bool postponed = false,
  bool makeRequired = true,
}) => activityStepBar(
  videoDone: video,
  workSent: work,
  quizDone: quiz,
  resultsDone: results,
  makePostponed: postponed,
  makeRequired: makeRequired,
);

void main() {
  group('which step is the current one', () {
    test('a new unit starts at Watch', () {
      final s = _bar();
      expect(s.current, ActivityStep.watch);
      expect(s.done, isEmpty);
    });

    test('the video done: Make', () {
      final s = _bar(video: true);
      expect(s.current, ActivityStep.make);
      expect(s.done, {ActivityStep.watch});
    });

    test('the work sent: Quiz (as in M-C21: Watch and Make done)', () {
      final s = _bar(video: true, work: true);
      expect(s.current, ActivityStep.quiz);
      expect(s.done, {ActivityStep.watch, ActivityStep.make});
    });

    test('the quiz done: Results', () {
      final s = _bar(video: true, work: true, quiz: true);
      expect(s.current, ActivityStep.results);
    });

    test('everything done, results seen: nothing is current', () {
      final s = _bar(video: true, work: true, quiz: true, results: true);
      expect(s.current, isNull);
      expect(s.done.length, 4);
    });

    test('Make postponed (R-66): the quiz is the current step', () {
      final s = _bar(video: true, postponed: true);
      expect(s.current, ActivityStep.quiz);
      expect(s.done, {ActivityStep.watch});
    });

    test('Make postponed, quiz done: Make comes back, then Results', () {
      final s = _bar(video: true, postponed: true, quiz: true);
      expect(s.current, ActivityStep.make);
      expect(s.done, {ActivityStep.watch, ActivityStep.quiz});
    });

    test('a unit with no work to send: Make counts as done', () {
      final s = _bar(video: true, makeRequired: false);
      expect(s.current, ActivityStep.quiz);
      expect(s.done, contains(ActivityStep.make));
    });
  });

  group('the bar', () {
    Future<void> pump(WidgetTester tester, ActivityStepBarState state) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ActivityStepBar(state: state)),
          ),
        );

    testWidgets('has the four labels of the design', (tester) async {
      await pump(tester, _bar());
      for (final l in ['Watch', 'Make', 'Quiz', 'Results']) {
        expect(find.text(l), findsOneWidget);
      }
    });

    testWidgets('done steps show a check, the others their number', (
      tester,
    ) async {
      await pump(tester, _bar(video: true, work: true));
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('exactly one step is the current one', (tester) async {
      await pump(tester, _bar(video: true));
      expect(find.byKey(const ValueKey('step-make-current')), findsOneWidget);
      expect(find.byKey(const ValueKey('step-watch-done')), findsOneWidget);
      expect(find.byKey(const ValueKey('step-quiz-todo')), findsOneWidget);
      expect(find.byKey(const ValueKey('step-results-todo')), findsOneWidget);
    });

    testWidgets('fits a 320 px phone with big text', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(body: ActivityStepBar(state: _bar())),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  test('the activity screen shows the bar under the header', () {
    final text = File(
      'lib/features/classroom/presentation/class_screen.dart',
    ).readAsStringSync();
    expect(text.contains('ActivityStepBar('), isTrue);
  });
}
