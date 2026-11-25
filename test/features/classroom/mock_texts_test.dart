import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/l10n/gen/app_localizations.dart';

/// The words of the Figma mocks: M-C01 (start), M-C03 (watch) and M-C22 (quiz
/// end). The 10 points in the Watch text are written in the text, on purpose
/// (decided with the product team).
final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  test('start (M-C01)', () {
    expect(
      _en.chatTodayPlay('ScratchJr'),
      "Today we're going to play with ScratchJr!\n"
      'Watch a short video, then make your own project.',
    );
  });

  test('watch (M-C03)', () {
    expect(
      _en.classWatchVideo,
      'Watch the video by clicking on the link below📹 and earn *10 points*🪩\n\n'
      'Click here 👇👇👇',
    );
  });

  test('quiz end (M-C22)', () {
    expect(
      _en.chatQuizEnd('Aarav', 4, 5, 5),
      'You are very smart Aarav!🤩\n'
      'You answered 4/5 questions correctly🤩 and earned 5 points🪩 in total!😍\n\n'
      'Amazing champ!😎',
    );
  });
}
