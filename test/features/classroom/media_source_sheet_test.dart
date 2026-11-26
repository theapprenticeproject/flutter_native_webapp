import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/media_source_sheet.dart';

/// Design M-S-02, "Choose an action": round icons with a word under each. The
/// WhatsApp browser on a phone opens the photo picker and offers no camera, so
/// the app asks first. A laptop opens its file dialog at once.
Future<MediaSource?> _open(
  WidgetTester tester, {
  required bool photo,
  required bool video,
  required String tap,
}) async {
  MediaSource? chosen;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => chosen = await showModalBottomSheet(
              context: context,
              builder: (_) =>
                  MediaSourceSheet(allowPhoto: photo, allowVideo: video),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.text('Choose an action'), findsOneWidget);
  if (tap.isNotEmpty) {
    await tester.tap(find.text(tap));
    await tester.pumpAndSettle();
  }
  return chosen;
}

void main() {
  // The mock's round buttons hold emoji: 📷 Camera, 🖼️ Photos, 📁 Files.
  testWidgets('each choice has its emoji in a white circle', (tester) async {
    await _open(tester, photo: true, video: true, tap: '');
    expect(find.text('📷'), findsOneWidget);
    expect(find.text('🎥'), findsOneWidget);
    expect(find.text('🖼️'), findsOneWidget);
    final circle = tester.widget<Container>(
      find
          .ancestor(of: find.text('📷'), matching: find.byType(Container))
          .first,
    );
    expect((circle.decoration! as BoxDecoration).color, Colors.white);
  });

  testWidgets('a photo activity: Camera and Photos', (tester) async {
    await _open(tester, photo: true, video: false, tap: '');
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Video'), findsNothing);
  });

  testWidgets('a video activity: Video and Photos, no photo Camera', (
    tester,
  ) async {
    await _open(tester, photo: false, video: true, tap: '');
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Camera'), findsNothing);
  });

  testWidgets('a photo or video activity: all three', (tester) async {
    await _open(tester, photo: true, video: true, tap: '');
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
  });

  testWidgets('each icon answers with its own choice', (tester) async {
    expect(
      await _open(tester, photo: true, video: true, tap: 'Camera'),
      MediaSource.camera,
    );
    expect(
      await _open(tester, photo: true, video: true, tap: 'Video'),
      MediaSource.video,
    );
    expect(
      await _open(tester, photo: true, video: true, tap: 'Photos'),
      MediaSource.library,
    );
  });

  test('only a phone asks first; a laptop opens its file dialog', () {
    expect(usesSourceSheet(TargetPlatform.android), isTrue);
    expect(usesSourceSheet(TargetPlatform.iOS), isTrue);
    for (final p in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      expect(usesSourceSheet(p), isFalse, reason: '$p');
    }
  });
}
