import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/providers/video_reward.dart';
import 'package:tapapp/l10n/gen/app_localizations.dart';

/// After the video the chat shows the points the Worker gave (R-41). When the
/// student watches the same video again the Worker answers `repeat: true` with
/// 0 points. Then we must not show the "10 points" picture or say "you earned".
final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  test('the first time: the points picture and the points the Worker gave', () {
    final r = videoReward(
      _en,
      studentName: 'Asha',
      points: 10,
      alreadyRecorded: false,
    );
    expect(r.image, 'assets/class-screen/10Points.png');
    expect(r.text, contains('Asha'));
    expect(r.text, contains('10 points'));
  });

  test('watched again, 0 points: no picture, and the reason', () {
    final r = videoReward(
      _en,
      studentName: 'Asha',
      points: 0,
      alreadyRecorded: true,
    );
    expect(r.image, isNull);
    expect(
      r.text,
      contains('Points are given only the first time you watch the video'),
    );
    expect(r.text, isNot(contains('earned')));
  });

  test('a repeat that still gave points is shown as normal', () {
    // The Worker's numbers win: we never decide the points ourselves.
    final r = videoReward(
      _en,
      studentName: 'Asha',
      points: 5,
      alreadyRecorded: true,
    );
    expect(r.image, isNotNull);
    expect(r.text, contains('5 points'));
  });

  test('0 points on a first watch is shown as normal too', () {
    final r = videoReward(
      _en,
      studentName: 'Asha',
      points: 0,
      alreadyRecorded: false,
    );
    expect(r.image, isNotNull);
  });
}
