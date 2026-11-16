/// "I'll do it later" on the Make step (R-66). Postponing writes nothing to the
/// server. The app knows the work is postponed because the video is done, the
/// quiz is done and there is no submission yet.
enum PostponeNext { quiz, leave }

/// "Do it later" goes on to the quiz. If the quiz is already done, nothing is
/// left today, so the student leaves (no loop of asking again).
PostponeNext afterDoItLater({required bool quizDone}) =>
    quizDone ? PostponeNext.leave : PostponeNext.quiz;

/// After the quiz, the app asks again "Are you ready to share your work?".
bool shouldAskToShareWork({
  required bool postponed,
  required bool quizDone,
  required bool workSent,
}) => postponed && quizDone && !workSent;
