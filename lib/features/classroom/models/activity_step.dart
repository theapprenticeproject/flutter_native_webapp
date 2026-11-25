/// The four steps of an activity, as in the step bar of the design.
enum ActivityStep { watch, make, quiz, results }

/// Which steps are done and which one is the current one. [current] is null
/// when everything is done.
class ActivityStepBarState {
  const ActivityStepBarState({required this.done, required this.current});

  final Set<ActivityStep> done;
  final ActivityStep? current;
}

/// The step bar for the flags the activity already keeps. A done step has a
/// check. The current step is the first one not done, in the order Watch, Make,
/// Quiz, Results, except that a postponed Make (R-66) is skipped until the quiz
/// is done, then it comes back. A unit with no work to send (no [makeRequired])
/// counts Make as done.
ActivityStepBarState activityStepBar({
  required bool videoDone,
  required bool workSent,
  required bool quizDone,
  required bool resultsDone,
  required bool makePostponed,
  bool makeRequired = true,
  bool rewardOpen = false,
}) {
  final done = <ActivityStep>{
    // While the video reward card is on screen, Watch is still the current step.
    if (videoDone && !rewardOpen) ActivityStep.watch,
    if (workSent || !makeRequired) ActivityStep.make,
    if (quizDone) ActivityStep.quiz,
    if (resultsDone) ActivityStep.results,
  };
  final skipMake = makePostponed && !quizDone;
  ActivityStep? current;
  for (final step in ActivityStep.values) {
    if (done.contains(step)) continue;
    if (step == ActivityStep.make && skipMake) continue;
    current = step;
    break;
  }
  return ActivityStepBarState(done: done, current: current);
}
