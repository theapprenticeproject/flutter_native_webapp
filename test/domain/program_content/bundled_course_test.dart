import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/program_content/bundled_course.dart';

/// In v1 all course content is bundled in the app (decided 2026-11-09). The
/// Worker's `course_id` must be one of these, or the app shows an error. It does
/// not quietly show another course.
///
/// THIS LIST IS THE CONTRACT with the backend: when a course is added to the
/// app, add its id here and tell the backend developer.
const bundledCourseIds = <String>{
  'Adult-Finance-financial-literacy-C12267',
  'Advanced-Art-Techniques-arts-C7982',
  'Advanced-Electronics-Kit-Less-science-lab-C5125',
  'Advanced-Electronics-science-lab-C4178',
  'Basic-Art-Skills-arts-C6083',
  'Basic-Electonics-Kit-less-science-lab-C3217', // "Electonics" is the real id
  'Basic-Electronics-science-lab-C2258',
  // The real id has brackets. The file name is the id, brackets included.
  'Coding-with-OctoStudio-(TapApp)',
  'Intermediate-Art-arts-C7031',
  'Master-Art-&-Expression-arts-C8933',
  'Money-Basics-financial-literacy-C9881',
  'OctoStudio-coding-C1567',
  'Real-Life-Money-financial-literacy-C11761',
  'Scratch-Jr-coding-C0078',
  'Smart-Savings-financial-literacy-C10813',
};

void main() {
  group('resolveBundledCourse', () {
    test('a bundled id is used as it is', () {
      expect(resolveBundledCourse('B', ['A', 'B']), 'B');
    });

    test('an id that is not bundled is an error, not another course', () {
      expect(
        () => resolveBundledCourse('CRS-SCI-05', ['A', 'B']),
        throwsA(
          isA<CourseNotBundledException>().having(
            (e) => e.courseId,
            'courseId',
            'CRS-SCI-05',
          ),
        ),
      );
    });

    test('a wrong capital letter or spelling is an error too', () {
      expect(
        () => resolveBundledCourse('basic-electronics-science-lab-c2258', [
          'Basic-Electronics-science-lab-C2258',
        ]),
        throwsA(isA<CourseNotBundledException>()),
      );
    });

    test('no id at all is an error', () {
      expect(
        () => resolveBundledCourse(null, ['A']),
        throwsA(isA<CourseNotBundledException>()),
      );
      expect(
        () => resolveBundledCourse('', ['A']),
        throwsA(isA<CourseNotBundledException>()),
      );
    });

    test('the error text never shows the id to the student', () {
      expect(
        const CourseNotBundledException('X').toString(),
        isNot(contains('Failed')),
      );
    });
  });

  group('the courses bundled in the app', () {
    Set<String> idsIn(String lang) => Directory('assets/data/courses/$lang')
        .listSync()
        .whereType<File>()
        .where(
          (f) => f.path.endsWith('.json') && !f.path.endsWith('index.json'),
        )
        .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
        .toSet();

    test('English has exactly the agreed list', () {
      expect(idsIn('en'), bundledCourseIds);
    });

    test('every other language has the same courses', () {
      for (final lang in ['hi', 'kn', 'mr', 'pa']) {
        expect(idsIn(lang), bundledCourseIds, reason: lang);
      }
    });

    test('the course index lists the same ids', () {
      final json =
          jsonDecode(
                File('assets/data/courses/en/index.json').readAsStringSync(),
              )
              as Map;
      final ids = [
        for (final c in json['courses'] as List) (c as Map)['id'] as String,
      ];
      expect(ids.toSet(), bundledCourseIds);
    });
  });

  test('the app has no silent fallback to the first course (R-44)', () {
    for (final path in [
      'lib/domain/learner/learner_state_provider.dart',
      'lib/domain/learner/learner_state_repository.dart',
    ]) {
      final text = File(path).readAsStringSync();
      expect(text.contains('courses.first'), isFalse, reason: path);
    }
  });
}
