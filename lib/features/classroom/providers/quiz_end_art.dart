/// The picture after the quiz. The design (C22) shows "WOW CHAMP" for a good
/// score and has no picture for a low one, so with nothing right there is none.
// shortcut: only 0 correct gets no picture, and one picture serves every other
// score. Design owes a picture for low scores and a limit for "good"; put them
// here.
String? quizEndArt({required int correct, required int total}) =>
    total > 0 && correct > 0 ? 'assets/class-screen/won-champ.png' : null;
