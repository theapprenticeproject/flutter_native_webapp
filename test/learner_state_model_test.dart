import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/models/learner_state_model.dart';

void main() {
  test('parses weekly activity field names returned by the backend', () {
    final state = LearnerStateModel.fromFullJson('learner-1', {
      'activities_watched_this_week': 2,
      'max_weekly_activities': 2,
      'activities_remaining': 0,
      'is_bingeing': true,
    });

    expect(state.unitsCompletedThisWeek, 2);
    expect(state.maxWeeklyUnits, 2);
    expect(state.unitsRemaining, 0);
    expect(state.isBingeing, isTrue);
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

  test('enforces the app weekly limit even when backend maximum is higher', () {
    final state = LearnerStateModel.fromFullJson('learner-1', {
      'activities_watched_this_week': 2,
      'max_weekly_activities': 5,
      'activities_remaining': 3,
      'is_bingeing': false,
    });

    expect(state.hasReachedWeeklyActivityLimit(), isTrue);
  });

  test('uses cached completions when the server count is stale', () {
    final state = LearnerStateModel.fromFullJson('learner-1', {
      'activities_watched_this_week': 0,
      'activities_remaining': 5,
      'is_bingeing': false,
    });

    expect(
      state.hasReachedWeeklyActivityLimit(localCompleted: 2),
      isTrue,
    );
  });
}
