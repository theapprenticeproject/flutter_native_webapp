import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:tapapp/domain/me/my_projects.dart';
import 'package:tapapp/features/me/project_text.dart';
import 'package:tapapp/l10n/gen/app_localizations.dart';
import 'package:tapapp/domain/program_content/course_detail_model.dart';
import 'package:tapapp/domain/progress/progress_models.dart';
import 'package:tapapp/domain/submission/feedback_state.dart';

/// R-87: "My projects this year" comes from the submissions and the course's
/// assignments. The labels follow the Figma: pending, given, wrong format.
CourseUnitModel _unit(String name, String aid) => CourseUnitModel(
  name: name,
  description: '',
  requiredComponents: '',
  difficulty: '',
  xp: 0,
  videos: const [],
  assignments: aid.isEmpty
      ? const []
      : [
          CourseAssignmentModel(
            id: 'a',
            sequence: 1,
            name: 'A',
            description: '',
            type: '',
            difficulty: '',
            steps: const [],
            assignmentId: aid,
          ),
        ],
);

SubmissionInfo _row(
  String aid, {
  String status = 'Completed',
  String result = 'Success - Original',
  int? score = 80,
  int attempt = 1,
  int left = 1,
  String? feedback,
}) => SubmissionInfo(
  id: 'S-$aid',
  assignmentId: aid,
  status: status,
  resultStatus: result,
  score: score,
  attemptNumber: attempt,
  attemptsRemaining: left,
  feedback: feedback,
  createdAt: DateTime.utc(2026, 11, 16, 8),
);

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  final now = DateTime.utc(2026, 11, 16, 12);
  final units = [for (var i = 1; i <= 8; i++) _unit('Unit $i', 'AS-$i')];

  test('a project for each unit, at most 6 a year (R-87)', () {
    expect(buildProjects(units, const [], now: now), hasLength(6));
  });

  test('nothing sent: every project is not started', () {
    final projects = buildProjects(units, const [], now: now);
    expect(projects.every((p) => p.stage == FeedbackStage.notSent), isTrue);
    expect(doneCount(projects), 0);
  });

  test('each state maps to the right label', () {
    final rows = [
      _row('AS-1'),
      _row('AS-2', status: 'Pending', result: 'Pending', score: null),
      _row('AS-3', result: 'Success - Flagged', left: 1),
      _row('AS-4', result: 'Failed', left: 0, attempt: 2),
    ];
    final p = buildProjects(units, rows, now: now);
    expect(p[0].labelOf(_en), 'Feedback given');
    expect(p[1].labelOf(_en), 'Feedback pending');
    expect(p[2].labelOf(_en), 'Wrong format');
    expect(p[3].labelOf(_en), 'Not accepted');
    expect(p[4].labelOf(_en), 'Not started');
  });

  test('3 of 6 done counts only valid work', () {
    final rows = [
      _row('AS-1'),
      _row('AS-2'),
      _row('AS-3'),
      _row('AS-4', result: 'Success - Flagged'),
      _row('AS-5', status: 'Pending', result: 'Pending', score: null),
    ];
    final p = buildProjects(units, rows, now: now);
    expect(doneCount(p), 3);
    expect(p.length, 6);
  });

  test('the newest attempt of a project decides its state', () {
    final rows = [
      _row('AS-1', result: 'Failed', attempt: 1),
      _row('AS-1', attempt: 2),
    ];
    expect(
      buildProjects(units, rows, now: now).first.labelOf(_en),
      'Feedback given',
    );
  });

  test('the Worker feedback and the unit name are carried to the detail', () {
    final p = buildProjects(units, [
      _row('AS-1', feedback: 'Great colours!'),
    ], now: now).first;
    expect(p.unitName, 'Unit 1');
    expect(p.feedback, 'Great colours!');
  });

  test('the Worker could not be reached: the saved states are used', () {
    final p = buildProjects(
      units,
      null,
      now: now,
      savedStage: (aid) => aid == 'AS-1' ? FeedbackStage.valid : null,
    );
    expect(p.first.stage, FeedbackStage.valid);
    expect(p[1].stage, FeedbackStage.notSent, reason: 'nothing saved for it');
  });

  group('the text in the project detail', () {
    MyProject withStage(FeedbackStage stage, {String? feedback}) => MyProject(
      unitName: 'U',
      assignmentId: 'AS-1',
      stage: stage,
      feedback: feedback,
    );

    test('given: the Worker feedback', () {
      expect(
        withStage(
          FeedbackStage.valid,
          feedback: 'Great colours!',
        ).detailOf(_en),
        'Great colours!',
      );
    });

    test('given but the Worker sent no text: a plain default', () {
      expect(withStage(FeedbackStage.valid).detailOf(_en), contains('valid'));
    });

    test('pending and slow: no feedback yet, and points come after', () {
      expect(
        withStage(FeedbackStage.waiting).detailOf(_en),
        contains('Points will be provided after feedback'),
      );
      expect(
        withStage(FeedbackStage.slow).detailOf(_en),
        contains('longer than expected'),
      );
    });

    test('wrong format: the reason, and how to send again', () {
      final d = withStage(
        FeedbackStage.notValid,
        feedback: 'Too dark.',
      ).detailOf(_en);
      expect(d, contains('Too dark.'));
      expect(d, contains('send'));
    });

    test('not started: says so', () {
      expect(
        withStage(FeedbackStage.notSent).detailOf(_en),
        contains('not sent'),
      );
    });
  });

  test('a unit with no assignment is not a project', () {
    final p = buildProjects(
      [_unit('No work', ''), _unit('Has work', 'AS-1')],
      const [],
      now: now,
    );
    expect(p, hasLength(1));
    expect(p.single.unitName, 'Has work');
  });

  test('pending for more than 24 hours says it is taking longer', () {
    final old = SubmissionInfo(
      id: 'S',
      assignmentId: 'AS-1',
      status: 'Pending',
      resultStatus: 'Pending',
      createdAt: DateTime.utc(2026, 11, 14),
    );
    expect(
      buildProjects(units, [old], now: now).first.labelOf(_en),
      'Taking longer than expected',
    );
  });
}
