/// Today's picture has 4 pieces (R-69). One piece unlocks for each step the
/// student finishes: the video, the work sent, the quiz. The 4th piece comes
/// only with valid feedback. The count does not depend on the order the steps
/// are done in, so a postponed Make (R-66) gives 2 of 4 after the quiz and 3 of
/// 4 when the work is sent.
int unlockedPieces({
  required bool videoDone,
  required bool workSent,
  required bool quizDone,
  required bool feedbackValid,
}) =>
    (videoDone ? 1 : 0) +
    (workSent ? 1 : 0) +
    (quizDone ? 1 : 0) +
    (feedbackValid ? 1 : 0);

/// How much of the picture is revealed: a quarter for each piece.
double pieceFraction(int pieces) => pieces.clamp(0, 4) / 4;

/// How long after the results screen the full picture sheet opens by itself
/// (mock M-C26b: "auto-opens ~2s"), so the student can read the feedback first.
const revealSheetDelay = Duration(seconds: 2);

/// Open the full picture sheet when the results screen shows, which is when the
/// 4th piece unlocks (R-69, mock M-C26b). [due] is true once per results screen,
/// also when the student comes back later and the work is already valid. Pieces
/// 1 to 3 show only in the badge. A wide screen has a side panel that already
/// shows the picture.
bool shouldShowRevealSheet({required bool due, required bool narrow}) =>
    due && narrow;
