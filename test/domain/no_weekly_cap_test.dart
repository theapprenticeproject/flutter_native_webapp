import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M0 / D0 / R-39: v1 has no weekly limit. The prototype rule "2 units a week"
/// is gone. The only pace rule in v1 is R-83: the next activity opens after
/// the work is sent and the feedback is valid. This test fails if any part of
/// the weekly cap comes back into `lib/`.
final _weeklyCapPieces = <String, RegExp>{
  'the session window files': RegExp(r'class_session_window'),
  'the session window classes': RegExp(r'ClassSessionWindow'),
  'the weekly limit check': RegExp(
    r'hasReachedWeekly|weeklyActivityLimit|_stateSaysCapped',
  ),
  'a "cap reached" outcome, message or flag': RegExp(
    r'weeklyCapReached|weeklyCapAlreadyReached|WeeklyCapReveal',
  ),
  'the weekly count fields': RegExp(
    r'unitsCompletedThisWeek|unitsRemaining|isBingeing|maxWeeklyUnits',
  ),
  'the weekly window dates': RegExp(r'windowStartDate|windowResetsOn'),
  'the weekly window cache keys': RegExp(r'sessionWindow|weeklyWatchWindow'),
  'the weekly cap JSON keys': RegExp(
    r'units_completed_this_week|activities_watched_this_week|max_weekly|'
    r'is_bingeing|window_start_date|window_resets_on|units_remaining|'
    r'activities_remaining',
  ),
};

void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (final entry in _weeklyCapPieces.entries) {
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
}
