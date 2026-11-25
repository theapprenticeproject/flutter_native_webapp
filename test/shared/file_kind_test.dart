import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/shared/media/file_kind.dart';

/// Design M-S-05: a text file picked for a photo must be refused with
/// "This is not a photo".
void main() {
  test('a photo: by the type the browser gives', () {
    expect(
      isRightFile(mimeType: 'image/jpeg', name: 'a', video: false),
      isTrue,
    );
    expect(
      isRightFile(mimeType: 'text/plain', name: 'a.jpg', video: false),
      isFalse,
    );
    expect(
      isRightFile(mimeType: 'video/mp4', name: 'a.mp4', video: false),
      isFalse,
    );
  });

  test('no type given: by the end of the name', () {
    expect(
      isRightFile(mimeType: null, name: 'IMG_1.JPG', video: false),
      isTrue,
    );
    expect(isRightFile(mimeType: '', name: 'photo.heic', video: false), isTrue);
    expect(
      isRightFile(mimeType: null, name: 'notes.txt', video: false),
      isFalse,
    );
    expect(
      isRightFile(mimeType: null, name: 'noending', video: false),
      isFalse,
    );
  });

  test('a video', () {
    expect(isRightFile(mimeType: 'video/mp4', name: 'a', video: true), isTrue);
    expect(isRightFile(mimeType: null, name: 'a.mov', video: true), isTrue);
    expect(
      isRightFile(mimeType: 'image/png', name: 'a.png', video: true),
      isFalse,
    );
  });
}
