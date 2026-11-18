import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/domain/gallery/gallery_models.dart';
import 'package:tapapp/features/gallery/presentation/gallery_view.dart';

/// R-6, R-59, R-85: the Gallery shows the student's own work, and a grid of
/// other students' valid work with initials only, a "Load more" button and a
/// viewer. With no work yet it shows a friendly empty state.
GalleryItem _item(String id, String initials, {bool video = false}) =>
    GalleryItem(
      submissionId: id,
      initials: initials,
      isVideo: video,
      url: 'https://r2.example/$id.webp',
    );

Future<void> _pump(
  WidgetTester tester, {
  String? ownWorkUrl,
  bool shared = false,
  List<GalleryItem> items = const [],
  bool loading = false,
  bool failed = false,
  bool hasMore = false,
  bool loadingMore = false,
  bool moreFailed = false,
  VoidCallback? onShare,
  VoidCallback? onLoadMore,
  VoidCallback? onRetry,
  void Function(int)? onOpen,
}) async {
  tester.view.physicalSize = const Size(420, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GalleryView(
          activityTitle: 'Build a Glowing LED Card',
          ownWorkUrl: ownWorkUrl,
          shared: shared,
          items: items,
          loading: loading,
          failed: failed,
          hasMore: hasMore,
          loadingMore: loadingMore,
          moreFailed: moreFailed,
          onShare: onShare ?? () {},
          onLoadMore: onLoadMore ?? () {},
          onRetry: onRetry ?? () {},
          onOpen: onOpen ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the activity title', (tester) async {
    await _pump(tester);
    expect(find.text('Build a Glowing LED Card'), findsOneWidget);
  });

  group('your submission', () {
    testWidgets('not shared: a box with a Share your work button', (
      tester,
    ) async {
      var shared = 0;
      await _pump(tester, onShare: () => shared++);
      expect(find.text('Your submission'), findsOneWidget);
      expect(find.text('Share your work'), findsOneWidget);
      await tester.tap(find.text('Share your work'));
      expect(shared, 1);
    });

    testWidgets("shared: shows the work and the \"You've shared\" tag", (
      tester,
    ) async {
      await _pump(
        tester,
        shared: true,
        ownWorkUrl: 'https://gcs.example/mine.webp',
      );
      expect(find.text("You've shared"), findsOneWidget);
      expect(find.text('Share your work'), findsNothing);
    });

    testWidgets('shared but the file link is not known: still says shared', (
      tester,
    ) async {
      await _pump(tester, shared: true);
      expect(find.text("You've shared"), findsOneWidget);
    });
  });

  group("other students' work", () {
    testWidgets('a grid with the heading and initials only', (tester) async {
      await _pump(
        tester,
        items: [_item('1', 'DS'), _item('2', 'A'), _item('3', 'MS')],
      );
      expect(find.text('From TAP students like you'), findsOneWidget);
      expect(find.text('DS'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('MS'), findsOneWidget);
    });

    testWidgets('a video tile says it is a video', (tester) async {
      await _pump(tester, items: [_item('1', 'DS', video: true)]);
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    });

    testWidgets('tapping a tile opens the viewer at that work', (tester) async {
      int? opened;
      await _pump(
        tester,
        items: [_item('1', 'DS'), _item('2', 'AB')],
        onOpen: (i) => opened = i,
      );
      await tester.tap(find.text('AB'));
      expect(opened, 1);
    });

    testWidgets('no work yet: a friendly empty state', (tester) async {
      await _pump(tester);
      expect(find.textContaining('No shared work yet'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('loading: a progress indicator, no empty text', (tester) async {
      await _pump(tester, loading: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('No shared work yet'), findsNothing);
    });

    testWidgets('could not load: a plain message and Try again', (
      tester,
    ) async {
      var retried = 0;
      await _pump(tester, failed: true, onRetry: () => retried++);
      expect(find.textContaining("couldn't load"), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });
  });

  group('Load more', () {
    testWidgets('shown when there is more, and it loads', (tester) async {
      var loads = 0;
      await _pump(
        tester,
        items: [_item('1', 'DS')],
        hasMore: true,
        onLoadMore: () => loads++,
      );
      await tester.tap(find.text('Load more'));
      expect(loads, 1);
    });

    testWidgets('hidden when there is no more', (tester) async {
      await _pump(tester, items: [_item('1', 'DS')]);
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('while loading more: a spinner, no second button', (
      tester,
    ) async {
      await _pump(
        tester,
        items: [_item('1', 'DS')],
        hasMore: true,
        loadingMore: true,
      );
      expect(find.text('Load more'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('load more failed: the work stays and the button comes back', (
      tester,
    ) async {
      await _pump(
        tester,
        items: [_item('1', 'DS')],
        hasMore: true,
        moreFailed: true,
      );
      expect(find.text('DS'), findsOneWidget);
      expect(find.textContaining("couldn't load more"), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);
    });
  });

  testWidgets('v1 has no time-left pill (R-72) and no student names', (
    tester,
  ) async {
    await _pump(tester, items: [_item('1', 'DS')]);
    expect(find.textContaining('Ends in'), findsNothing);
    expect(find.textContaining('left'), findsNothing);
  });

  // The R2 picture links have no CORS headers. On the web, Flutter downloads a
  // picture's bytes by default, which then fails and shows only the placeholder.
  // `fallback` uses a plain browser <img> when the download fails, which needs
  // no CORS.
  testWidgets(
    'pictures fall back to a browser image, so R2 links without CORS show',
    (tester) async {
      await _pump(
        tester,
        shared: true,
        ownWorkUrl: 'https://gcs.example/mine.webp',
        items: [_item('1', 'DS'), _item('2', 'AB')],
      );
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, greaterThanOrEqualTo(3));
      for (final image in images) {
        final provider = image.image;
        expect(provider, isA<NetworkImage>());
        expect(
          (provider as NetworkImage).webHtmlElementStrategy,
          WebHtmlElementStrategy.fallback,
        );
      }
    },
  );
}
