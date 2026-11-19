import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/learning_progress/picture_pieces.dart';

/// R-69 and the mock M-C26b: the partial picture lives in the badge (quarters).
/// The big "Today's picture" sheet opens by itself only when all 4 pieces are
/// open. On a wide screen the side panel already shows the picture.
void main() {
  test('a narrow screen opens the sheet when the 4th piece unlocks', () {
    expect(
      shouldShowRevealSheet(previous: 3, current: 4, narrow: true),
      isTrue,
    );
  });

  test('pieces 1 to 3 open no sheet: the badge shows them', () {
    expect(
      shouldShowRevealSheet(previous: 1, current: 2, narrow: true),
      isFalse,
    );
    expect(
      shouldShowRevealSheet(previous: 0, current: 1, narrow: true),
      isFalse,
    );
    expect(
      shouldShowRevealSheet(previous: 2, current: 3, narrow: true),
      isFalse,
    );
  });

  test('a wide screen does not: the side panel already shows it', () {
    expect(
      shouldShowRevealSheet(previous: 3, current: 4, narrow: false),
      isFalse,
    );
  });

  test('nothing new unlocked: no sheet', () {
    expect(
      shouldShowRevealSheet(previous: 4, current: 4, narrow: true),
      isFalse,
    );
  });

  test('going down (a new unit) does not show a sheet', () {
    expect(
      shouldShowRevealSheet(previous: 4, current: 0, narrow: true),
      isFalse,
    );
  });

  test('opening the class with 4 pieces already shows nothing', () {
    // The first value we see is the starting point, not a new unlock.
    expect(
      shouldShowRevealSheet(previous: null, current: 4, narrow: true),
      isFalse,
    );
  });
}
