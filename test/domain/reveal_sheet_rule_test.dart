import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/learning_progress/picture_pieces.dart';

/// R-69 and the mock M-C26b: the partial picture lives in the badge (quarters).
/// The big "Today's picture" sheet opens by itself when the results screen shows
/// (all 4 pieces open), about 2 seconds later. On a wide screen the side panel
/// already shows the picture.
void main() {
  test('a narrow screen opens the sheet with the results screen', () {
    expect(shouldShowRevealSheet(due: true, narrow: true), isTrue);
  });

  test('no results screen, no sheet: the badge shows pieces 1 to 3', () {
    expect(shouldShowRevealSheet(due: false, narrow: true), isFalse);
  });

  test('a wide screen has the side panel, so no sheet', () {
    expect(shouldShowRevealSheet(due: true, narrow: false), isFalse);
  });

  test('the wait is 2 seconds', () {
    expect(revealSheetDelay, const Duration(seconds: 2));
  });
}
