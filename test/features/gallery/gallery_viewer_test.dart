import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/gallery/gallery_models.dart';
import 'package:tapapp/features/gallery/presentation/gallery_viewer.dart';

/// R-6: a full-screen viewer, "1 of 9", previous and next, "Swipe to see more".
/// A student who has not shared sees "Want to share your work too?".
GalleryItem _item(String id, {bool video = false}) => GalleryItem(
  submissionId: id,
  initials: id.toUpperCase(),
  isVideo: video,
  url: 'https://r2.example/$id.webp',
);

Future<void> _pump(
  WidgetTester tester, {
  required List<GalleryItem> items,
  int index = 0,
  bool canShare = false,
  VoidCallback? onShare,
  void Function(String url)? onOpenVideo,
}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GalleryViewer(
                    items: items,
                    initialIndex: index,
                    canShare: canShare,
                    onShare: onShare ?? () {},
                    onOpenVideo: onOpenVideo ?? (_) {},
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  final three = [_item('a'), _item('b'), _item('c')];

  testWidgets('shows "1 of 3" and the swipe hint', (tester) async {
    await _pump(tester, items: three);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Swipe to see more'), findsOneWidget);
  });

  testWidgets('starts at the tapped work', (tester) async {
    await _pump(tester, items: three, index: 2);
    expect(find.text('3 of 3'), findsOneWidget);
  });

  testWidgets('the next and previous arrows move through the works', (
    tester,
  ) async {
    await _pump(tester, items: three);
    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsOneWidget);
  });

  testWidgets('swiping moves to the next work', (tester) async {
    await _pump(tester, items: three);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
  });

  testWidgets('the previous arrow is off at the first work', (tester) async {
    await _pump(tester, items: three);
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the next arrow is off at the last work', (tester) async {
    await _pump(tester, items: three, index: 2);
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the close button leaves the viewer', (tester) async {
    await _pump(tester, items: three);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a student who has not shared is invited to', (tester) async {
    var shared = 0;
    await _pump(tester, items: three, canShare: true, onShare: () => shared++);
    expect(find.text('Want to share your work too?'), findsOneWidget);
    await tester.tap(find.text('Share your work'));
    expect(shared, 1);
  });

  testWidgets('a student who has shared sees no invitation', (tester) async {
    await _pump(tester, items: three);
    expect(find.text('Want to share your work too?'), findsNothing);
  });

  testWidgets('a video offers to open it', (tester) async {
    String? opened;
    await _pump(
      tester,
      items: [_item('v', video: true)],
      onOpenVideo: (url) => opened = url,
    );
    await tester.tap(find.text('Open video'));
    expect(opened, 'https://r2.example/v.webp');
  });

  testWidgets('the viewer picture also falls back to a browser image', (
    tester,
  ) async {
    await _pump(tester, items: three);
    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      (image.image as NetworkImage).webHtmlElementStrategy,
      WebHtmlElementStrategy.fallback,
    );
  });
}
