import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/learner/learner_state_model.dart';

void main() {
  test('ignores the old weekly limit fields and never saves them (R-39)', () {
    // The prototype backend still sends these. v1 has no weekly limit.
    final state = LearnerStateModel.fromFullJson('learner-1', {
      'xp': 120,
      'activities_watched_this_week': 2,
      'units_completed_this_week': 2,
      'max_weekly_activities': 2,
      'max_weekly_units': 2,
      'activities_remaining': 0,
      'units_remaining': 0,
      'is_bingeing': true,
      'window_start_date': '2026-11-02',
      'window_resets_on': '2026-11-09',
    });

    expect(state.xp, 120, reason: 'the other fields must still be read');

    final saved = state.toJson();
    for (final key in const [
      'activities_watched_this_week',
      'units_completed_this_week',
      'max_weekly_activities',
      'max_weekly_units',
      'activities_remaining',
      'units_remaining',
      'is_bingeing',
      'window_start_date',
      'window_resets_on',
    ]) {
      expect(saved.containsKey(key), isFalse, reason: '$key must not be saved');
    }
  });

  test('keeps learner and active-course submission indexes separate', () {
    final state = LearnerStateModel.fromFullJson('TL00017423', {
      'submission_index': 3,
      'enrollment': {
        'course': 'course-1',
        'videos_completed': 0,
        'quizzes_completed': 0,
        'submission_index': 0,
      },
    });

    expect(state.submissionIndex, 3);
    expect(state.enrollment?.submissionIndex, 0);
  });
}
