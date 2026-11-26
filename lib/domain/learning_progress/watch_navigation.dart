/// What the activity screen does when its address changes between
/// `/classroom` and `/classroom?step=video`.
enum WatchNav { none, open, backToStart }

/// Tapping "Watch" moves the address to the video, so the phone Back button
/// has a step to go back to. Back from the video shows the Watch start screen
/// again. After "I watched it" the step is saved on the server and cannot be
/// undone, so Back then changes nothing on the screen (it leaves the activity).
WatchNav watchNavFor({
  required bool wasOpen,
  required bool isOpen,
  required bool watched,
}) {
  if (!wasOpen && isOpen) return WatchNav.open;
  if (wasOpen && !isOpen && !watched) return WatchNav.backToStart;
  return WatchNav.none;
}
