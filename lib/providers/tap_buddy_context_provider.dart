import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/learner_state_model.dart';
import 'class_session_bootstrap_provider.dart';
import 'learner_state_provider.dart';
import 'profile_provider.dart';

class TapBuddyContext {
  const TapBuddyContext({
    this.studentName,
    this.grade,
    this.courseName,
    this.unitName,
    this.unitDescription,
    this.xp,
    this.streak,
    this.hasReachedWeeklyCap = false,
    this.hasActiveClassSession = false,
  });

  final String? studentName;
  final String? grade;
  final String? courseName;
  final String? unitName;
  final String? unitDescription;
  final int? xp;
  final int? streak;
  final bool hasReachedWeeklyCap;
  final bool hasActiveClassSession;

  Map<String, dynamic> toJson() => {
    if (studentName != null) 'student_name': studentName,
    if (grade != null) 'grade': grade,
    if (courseName != null) 'course_name': courseName,
    if (unitName != null) 'unit_name': unitName,
    if (unitDescription != null) 'unit_description': unitDescription,
    if (xp != null) 'xp': xp,
    if (streak != null) 'streak': streak,
    'has_reached_weekly_cap': hasReachedWeeklyCap,
    'has_active_class_session': hasActiveClassSession,
  };
}

final tapBuddyContextProvider = FutureProvider.autoDispose<TapBuddyContext>((
  ref,
) async {
  final activeProfile = await ref.watch(activeProfileProvider.future);
  if (activeProfile == null) return const TapBuddyContext();

  LearnerStateModel? learnerState;
  try {
    learnerState = await ref.watch(
      learnerStateDataProvider(activeProfile.learnerId).future,
    );
  } catch (_) {
    learnerState = null;
  }

  try {
    final bootstrap = await ref.watch(classSessionBootstrapProvider.future);
    return TapBuddyContext(
      studentName:
          bootstrap.learnerState.profile?.studentName ??
          activeProfile.studentName,
      grade: activeProfile.grade,
      courseName: bootstrap.courseName,
      unitName: bootstrap.unit?.name,
      unitDescription: bootstrap.unit?.description,
      xp: bootstrap.learnerState.xp,
      streak: bootstrap.learnerState.streak,
      hasReachedWeeklyCap: bootstrap.weeklyCapAlreadyReached,
      hasActiveClassSession: bootstrap.unit != null,
    );
  } catch (_) {
    return TapBuddyContext(
      studentName:
          learnerState?.profile?.studentName ?? activeProfile.studentName,
      grade: activeProfile.grade,
      courseName: learnerState?.enrollment?.course,
      xp: learnerState?.xp,
      streak: learnerState?.streak,
      hasReachedWeeklyCap:
          learnerState?.hasReachedWeeklyActivityLimit() ?? false,
      hasActiveClassSession: false,
    );
  }
});
