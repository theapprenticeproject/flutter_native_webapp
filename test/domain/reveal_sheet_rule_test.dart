import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/learning_progress/picture_pieces.dart';

/// R-69: the student sees the picture get revealed. On a wide screen the side
/// panel shows it. On a narrow one (a phone) there is no panel, so a sheet
/// shows it when a piece unlocks.
void main() {
  test('a narrow screen shows the sheet when a piece unlocks', () {
    expect(
      shouldShowRevealSheet(previous: 1, current: 2, narrow: true),
      isTrue,
    );
    expect(
      shouldShowRevealSheet(previous: 0, current: 1, narrow: true),
      isTrue,
    );
  });

  test('a wide screen does not: the side panel already shows it', () {
    expect(
      shouldShowRevealSheet(previous: 1, current: 2, narrow: false),
      isFalse,
    );
  });

  test('nothing new unlocked: no sheet', () {
    expect(
      shouldShowRevealSheet(previous: 2, current: 2, narrow: true),
      isFalse,
    );
  });

  test('going down (a new unit) does not show a sheet', () {
    expect(
      shouldShowRevealSheet(previous: 4, current: 0, narrow: true),
      isFalse,
    );
  });

  test('opening the class with pieces already unlocked shows nothing', () {
    // The first value we see is the starting point, not a new unlock.
    expect(
      shouldShowRevealSheet(previous: null, current: 2, narrow: true),
      isFalse,
    );
  });
}
