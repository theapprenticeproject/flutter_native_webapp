import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// QA: the camera opened, but the photo showed black on "Check your work before
/// sending". The picker was told `imageQuality: 85`. On the web the picker then
/// re-draws the photo on a hidden canvas to compress it, and a big camera photo
/// (50 to 100 megapixels) is larger than the canvas many phones allow, so it
/// came back blank. The app gets the original file and makes it smaller itself
/// (`encodeImage`: createImageBitmap, which handles big photos).
void main() {
  final source = File(
    'lib/features/classroom/presentation/widgets/class_submission_card.dart',
  ).readAsStringSync();

  test('the picker is not asked to compress the photo', () {
    expect(source.contains('imageQuality'), isFalse);
  });

  test('a photo is made smaller by the app before it is shown or sent', () {
    expect(source.contains('encodeImage('), isTrue);
  });
}
