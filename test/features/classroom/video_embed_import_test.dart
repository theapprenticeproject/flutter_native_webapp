import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The video card must use the real YouTube iframe on the web. It once imported
/// the empty stub for every platform, so no iframe was made and no video played.
void main() {
  test('the video card imports the web embed on the web', () {
    final text = File(
      'lib/features/classroom/presentation/widgets/class_video_card.dart',
    ).readAsStringSync();
    expect(
      RegExp(
        r"import 'youtube_embed_stub.dart'\s+if \(dart\.library\.js_interop\) 'youtube_embed_web.dart';",
      ).hasMatch(text),
      isTrue,
      reason: 'the stub must be chosen only when there is no browser',
    );
  });

  test('the web embed points at youtube.com/embed with the video id', () {
    final text = File(
      'lib/features/classroom/presentation/widgets/youtube_embed_web.dart',
    ).readAsStringSync();
    expect(text.contains('https://www.youtube.com/embed/'), isTrue);
  });
}
