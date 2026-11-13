import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The v1 Worker has no `/learner/*` routes. Unit steps are recorded one by one
/// (`/progress/...`), and the unit and the step are kept on the phone. The old
/// calls (`/learner/state`, `/learner/enroll`, `/learner/submit-progress`) and
/// `/progress/last_submission` (the contract says `sync` is enough) must not
/// come back.
final _forbidden = <String, RegExp>{
  'an old /learner/ route': RegExp(r'''['"]/learner/'''),
  'the old unit-complete call': RegExp(r'submitProgress|submit-progress'),
  'the old progress-conflict error': RegExp(r'ProgressConflictException'),
  'the unused /progress/last_submission call': RegExp(
    r'progress/last_submission|LastSubmissionResult|\blastSubmission\(',
  ),
};

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final entry in _forbidden.entries) {
    test('lib/ has no ${entry.key}', () {
      final found = <String>[];
      for (final f in files) {
        for (final line in f.readAsLinesSync()) {
          if (entry.value.hasMatch(line)) {
            found.add('${f.path}: ${line.trim()}');
          }
        }
      }
      expect(found, isEmpty);
    });
  }
}
