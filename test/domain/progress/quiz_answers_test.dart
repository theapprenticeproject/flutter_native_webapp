import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/program_content/course_detail_model.dart';
import 'package:tapapp/domain/progress/quiz_answers.dart';

CourseQuizQuestionModel _q({
  String id = 'QN-1',
  Map<String, String> options = const {'1': 'x', '2': 'y', '3': 'z'},
  String answer = '2',
}) => CourseQuizQuestionModel(
  question: 'Q?',
  options: options,
  answerKey: answer,
  questionId: id,
);

/// Content bugs sent back to the curriculum team (2026-11-18): option "1" is
/// missing, so the right answer cannot be chosen. Delete an entry when the
/// content is fixed.
const _knownMissingOption = {
  'RacetheSchoolBus Q1QN62753',
  'Build the Ultimate Savings Tower Challenge Q1QN62773',
};

void main() {
  // The real Worker answers INVALID_INPUT to letters: "each answer needs a
  // question_id and a numeric selected_key (e.g. "1", "2", "3")".
  test('sends the option key as it is: a number as text, "1/2/3"', () {
    expect(quizAnswerFor(_q(), '1').selectedKey, '1');
    expect(quizAnswerFor(_q(), '2').selectedKey, '2');
    expect(quizAnswerFor(_q(), '3').selectedKey, '3');
    expect(quizAnswerFor(_q(id: 'QN-9'), '1').questionId, 'QN-9');
  });

  test(
    'refuses an answer it cannot send (no id, or a key that is no number)',
    () {
      expect(() => quizAnswerFor(_q(id: ''), '1'), throwsStateError);
      expect(() => quizAnswerFor(_q(), 'x'), throwsStateError);
      expect(() => quizAnswerFor(_q(), '0'), throwsStateError);
      expect(() => quizAnswerFor(_q(), 'a'), throwsStateError);
    },
  );

  test('every bundled question can be sent: it has an id and a valid key', () {
    final problems = <String>[];
    var questions = 0;
    for (final f in Directory(
      'assets/data/courses',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.json')) continue;
      final json = jsonDecode(f.readAsStringSync());
      if (json is! Map || json['units'] is! List) continue;
      for (final unit in json['units'] as List) {
        final quiz = (unit as Map)['quiz'];
        if (quiz is! Map) continue;
        if ((quiz['zid'] as String? ?? '').isEmpty) {
          problems.add('${f.path}: quiz of ${unit['uid']} has no zid');
        }
        for (final raw in (quiz['qs'] as List? ?? const [])) {
          questions++;
          final q = CourseQuizQuestionModel.fromJson(
            Map<String, dynamic>.from(raw as Map),
          );
          if (q.questionId.isEmpty) {
            problems.add('${f.path}: a question has no qid');
          }
          if ((int.tryParse(q.answerKey) ?? 0) < 1) {
            problems.add(
              '${f.path}: ${q.questionId} answer "${q.answerKey}" is no key',
            );
          }
          if (!q.options.containsKey(q.answerKey) &&
              !_knownMissingOption.contains(q.questionId)) {
            problems.add(
              '${f.path}: ${q.questionId} answer "${q.answerKey}" is not an option',
            );
          }
        }
      }
    }
    expect(questions, greaterThan(0));
    expect(problems, isEmpty, reason: problems.take(5).join('\n'));
  });
}
