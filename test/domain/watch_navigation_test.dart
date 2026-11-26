import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/learning_progress/watch_navigation.dart';

/// QA: on the video screen the phone Back button went straight to Home. It must
/// go to the Watch start screen first. Tapping "Watch" moves the address to
/// `/classroom?step=video`, and Back returns to `/classroom`.
void main() {
  test('Watch tapped: the address turns to video, the video opens', () {
    expect(
      watchNavFor(wasOpen: false, isOpen: true, watched: false),
      WatchNav.open,
    );
  });

  test('Back from the video, not watched yet: the start screen comes back', () {
    expect(
      watchNavFor(wasOpen: true, isOpen: false, watched: false),
      WatchNav.backToStart,
    );
  });

  test('after "I watched it" the video cannot be undone: nothing changes', () {
    expect(
      watchNavFor(wasOpen: true, isOpen: false, watched: true),
      WatchNav.none,
    );
  });

  test('no change of address: nothing to do', () {
    expect(
      watchNavFor(wasOpen: false, isOpen: false, watched: false),
      WatchNav.none,
    );
    expect(
      watchNavFor(wasOpen: true, isOpen: true, watched: false),
      WatchNav.none,
    );
  });
}
