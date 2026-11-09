import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M0 / D0: v1 has no streaks, no gems and no archetype (R-39, section 2 of
/// the requirements, `tapapp-changes.md`). This test fails if any of them
/// comes back into `lib/`.
///
/// The archetype ladder (`LearnerArchetype`) and the step selector stay for
/// now. The flow uses one fixed value until M3 to M5 rebuild the activity.
final _removedPieces = <String, RegExp>{
  'any streak code or text': RegExp(r'streak', caseSensitive: false),
  'any gem code or text': RegExp(
    r'gems?(?![a-z])|gemBg|submissionGems|skillGems',
    caseSensitive: false,
  ),
  'the archetype calculator from the streak': RegExp(
    r'LocalArchetypeCalculator|ArchetypeConstants|_reconcileArchetype|'
    r'local_archetype_calculator',
  ),
  'the last activity date (only used by the archetype)': RegExp(
    r'lastActivityDate|last_activity_date',
  ),
  'the archetype in the learner state or its JSON': RegExp(
    r"'archetype'|\.archetype\b|this\.archetype|String\? archetype|,archetype\b",
  ),
};

void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (final entry in _removedPieces.entries) {
    test('lib/ has no ${entry.key}', () {
      final found = <String>[];
      for (final file in dartFiles) {
        if (entry.value.hasMatch(file.path) ||
            entry.value.hasMatch(file.readAsStringSync())) {
          found.add(file.path);
        }
      }
      expect(found, isEmpty, reason: 'Still found in: $found');
    });
  }

  test('every student gets the photo or video submission step (R-63)', () {
    // The fixed archetype must be the one that picks the richest step.
    final controller = File(
      'lib/features/classroom/providers/class_chat_controller.dart',
    ).readAsStringSync();
    expect(
      controller,
      contains('String get _currentArchetype => LearnerArchetype.submitter;'),
    );
  });
}
