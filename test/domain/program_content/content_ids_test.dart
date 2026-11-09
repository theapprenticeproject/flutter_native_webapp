import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/program_content/course_detail_model.dart';

/// The API needs a unit id, a question id and an assignment id. The bundled
/// course files carry them as `uid`, `qid` and `aid` (see scripts/content_ids.py).
/// These tests make sure every id is there, unique, and the same in each language.
const _langs = ['en', 'hi', 'kn', 'mr', 'pa'];

List<File> _courseFiles(String lang) =>
    Directory('assets/data/courses/$lang')
        .listSync()
        .whereType<File>()
        .where(
          (f) => f.path.endsWith('.json') && !f.path.endsWith('/index.json'),
        )
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

String _name(File f) => f.uri.pathSegments.last;

List<String> _idsOf(CourseDetailModel course) {
  final ids = <String>[];
  for (final unit in course.units) {
    ids.add(unit.unitId);
    for (final a in unit.assignments) {
      ids.add(a.assignmentId);
    }
    for (final q in unit.quiz?.questions ?? const <CourseQuizQuestionModel>[]) {
      ids.add(q.questionId);
    }
    for (final v in unit.videos) {
      for (final q
          in v.postQuiz?.questions ?? const <CourseQuizQuestionModel>[]) {
        ids.add(q.questionId);
      }
    }
  }
  return ids;
}

CourseDetailModel _load(File f) => CourseDetailModel.fromJson(
  jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
);

void main() {
  test('every unit, question and assignment has an id', () {
    for (final lang in _langs) {
      for (final f in _courseFiles(lang)) {
        final ids = _idsOf(_load(f));
        expect(ids, isNotEmpty, reason: '$lang/${_name(f)}');
        expect(
          ids.where((id) => id.isEmpty),
          isEmpty,
          reason: '$lang/${_name(f)} has a missing id',
        );
      }
    }
  });

  test('ids are unique, also across courses', () {
    final seen = <String, String>{};
    for (final f in _courseFiles('en')) {
      final ids = _idsOf(_load(f));
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'duplicate in ${_name(f)}',
      );
      for (final id in ids) {
        expect(
          seen.containsKey(id),
          isFalse,
          reason: '$id is used in ${seen[id]} and ${_name(f)}',
        );
        seen[id] = _name(f);
      }
    }
  });

  test('every language has the same files and the same ids', () {
    final english = _courseFiles('en');
    for (final lang in _langs.skip(1)) {
      final files = _courseFiles(lang);
      expect(
        files.map(_name).toList(),
        english.map(_name).toList(),
        reason: '$lang has different course files',
      );
      for (var i = 0; i < english.length; i++) {
        expect(
          _idsOf(_load(files[i])),
          _idsOf(_load(english[i])),
          reason: '$lang/${_name(files[i])} has different ids than en',
        );
      }
    }
  });

  test('the answer key maps to the API letters', () {
    const q = CourseQuizQuestionModel(
      question: 'q',
      options: {'1': 'x', '2': 'y', '3': 'z'},
      answerKey: '2',
    );
    expect(q.answerLetter, 'b');
    expect(CourseQuizQuestionModel.letterForOptionKey('1'), 'a');
    expect(CourseQuizQuestionModel.letterForOptionKey('3'), 'c');
    expect(CourseQuizQuestionModel.letterForOptionKey('x'), '');
    expect(
      const CourseQuizQuestionModel(
        question: 'q',
        options: {},
        answerKey: '',
      ).answerLetter,
      '',
    );
  });
}
