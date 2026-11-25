import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_reveal_widgets.dart';
import 'package:tapapp/features/classroom/presentation/widgets/picture_badge.dart';
import 'package:tapapp/features/classroom/presentation/widgets/picture_quarters.dart';

/// The design (M-C03, M-C05, M-C26b): today's picture opens one quarter at a
/// time, in a round badge with "?" on the closed quarters, and in the full
/// picture sheet. It is not a cloud that shrinks.
const _asset = 'assets/reveal/1.webp';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

Finder _open(int i) => find.byKey(ValueKey('quarter-$i-open'));
Finder _closed(int i) => find.byKey(ValueKey('quarter-$i-closed'));

void main() {
  group('PictureQuarters', () {
    for (final n in [0, 1, 2, 3, 4]) {
      testWidgets('$n pieces: the first $n quarters are open, the rest "?"', (
        tester,
      ) async {
        await _pump(
          tester,
          SizedBox(
            width: 120,
            child: PictureQuarters(asset: _asset, pieces: n),
          ),
        );
        for (var i = 0; i < 4; i++) {
          expect(_open(i), i < n ? findsOneWidget : findsNothing, reason: '$i');
          expect(
            _closed(i),
            i < n ? findsNothing : findsOneWidget,
            reason: '$i',
          );
        }
        expect(find.text('?'), findsNWidgets(4 - n));
      });
    }

    testWidgets('a count outside 0 to 4 is kept inside the range', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 120,
          child: PictureQuarters(asset: _asset, pieces: 9),
        ),
      );
      expect(find.text('?'), findsNothing);
    });

    testWidgets('each open quarter is its own part of the full-size picture', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 120,
          child: PictureQuarters(asset: _asset, pieces: 4),
        ),
      );
      // The whole picture is laid out at 120 x 120 from the grid's top left,
      // and each quarter shows its part of it. (A quarter that squeezed the
      // whole picture into 60 x 60 would show a tiny full picture instead.)
      final grid = tester.getTopLeft(find.byType(PictureQuarters));
      for (var i = 0; i < 4; i++) {
        final image = tester.getRect(
          find.descendant(of: _open(i), matching: find.byType(Image)),
        );
        expect(tester.getSize(_open(i)), const Size(60, 60), reason: '$i');
        expect(image.size, const Size(120, 120), reason: 'quarter $i');
        expect(image.topLeft, grid, reason: 'quarter $i');
      }
    });

    testWidgets('can be round, for the badge', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 60,
          child: PictureQuarters(asset: _asset, pieces: 1, circle: true),
        ),
      );
      expect(find.byType(ClipOval), findsOneWidget);
    });
  });

  group('PictureBadge', () {
    testWidgets('is a round picture in 4 quarters with the n/4 pill', (
      tester,
    ) async {
      await _pump(tester, const PictureBadge(pieces: 1, asset: _asset));
      expect(find.text('1/4'), findsOneWidget);
      expect(find.byType(PictureQuarters), findsOneWidget);
      expect(_open(0), findsOneWidget);
      expect(_closed(1), findsOneWidget);
    });
  });

  group('the full picture sheet', () {
    Future<void> openSheet(WidgetTester tester, int pieces) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showRevealSheet(
                  context,
                  unitIndex: 0,
                  pieces: pieces,
                  asset: _asset,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('4 pieces: "You opened the full picture!"', (tester) async {
      await openSheet(tester, 4);
      expect(find.text("Today's picture"), findsOneWidget);
      expect(find.text('You opened the full picture! 🥳'), findsOneWidget);
      expect(
        find.text('You finished all 4 steps. Great job, champ!'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('picture-bar-3-on')), findsOneWidget);
      expect(find.text('?'), findsNothing);
    });

    testWidgets('2 pieces: the picture is in quarters, 2 bars are filled', (
      tester,
    ) async {
      await openSheet(tester, 2);
      expect(find.text('2 of 4 pieces opened'), findsOneWidget);
      expect(find.text('?'), findsNWidgets(2));
      expect(find.byKey(const ValueKey('picture-bar-1-on')), findsOneWidget);
      expect(find.byKey(const ValueKey('picture-bar-2-off')), findsOneWidget);
    });

    testWidgets('the X closes it', (tester) async {
      await openSheet(tester, 4);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text("Today's picture"), findsNothing);
    });
  });

  test('the shrinking cloud is gone', () {
    final text = File(
      'lib/features/classroom/presentation/widgets/class_reveal_widgets.dart',
    ).readAsStringSync();
    expect(text.contains('_CloudRevealPainter'), isFalse);
    expect(text.contains("'???'"), isFalse);
    expect(text.contains('BackdropFilter'), isFalse);
  });

  // QA bug 14: the floating badge covered the end of the last item (the Confirm
  // button). The chat list must end with enough room to scroll that item up
  // above the badge.
  group('the badge does not cover the end of the chat', () {
    test('the room at the bottom is larger than the badge and its margin', () {
      expect(
        PictureBadge.clearance,
        greaterThan(PictureBadge.size + PictureBadge.margin),
      );
    });

    test('the class screen uses it for the list and for the badge', () {
      final text = File(
        'lib/features/classroom/presentation/class_screen.dart',
      ).readAsStringSync();
      expect(text.contains('PictureBadge.clearance'), isTrue);
      expect(text.contains('right: PictureBadge.margin'), isTrue);
      expect(text.contains('bottom: PictureBadge.margin'), isTrue);
    });
  });

  // QA bug 15: the closed quarters are a checkerboard in the design (M-C03,
  // M-C05, M-C21): light top left, dark top right, dark bottom left, light
  // bottom right.
  group('closed quarters follow the design\'s checkerboard', () {
    Color colorOf(WidgetTester tester, int i) => tester
        .widget<ColoredBox>(
          find.descendant(of: _closed(i), matching: find.byType(ColoredBox)),
        )
        .color;

    testWidgets('light, dark, dark, light', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 120,
          child: PictureQuarters(asset: _asset, pieces: 0),
        ),
      );
      const light = Color(0xFFE4E4FB);
      const dark = Color(0xFF5B5BD6);
      expect(colorOf(tester, 0), light);
      expect(colorOf(tester, 1), dark);
      expect(colorOf(tester, 2), dark);
      expect(colorOf(tester, 3), light);
    });
  });

  // QA bug 7: a grey ring around the badge with a purple arc over it. The arc
  // starts at 12 o'clock and runs clockwise: a quarter of the ring for each open
  // piece.
  group('the badge ring', () {
    for (final n in [1, 2, 3, 4]) {
      testWidgets('$n pieces: an arc of $n quarters from 12 o\'clock', (
        tester,
      ) async {
        await _pump(tester, PictureBadge(pieces: n, asset: _asset));
        final ring = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PictureRingPainter,
        );
        expect(ring, findsOneWidget);
        expect(
          tester.renderObject(ring),
          paints..arc(startAngle: -math.pi / 2, sweepAngle: n * math.pi / 2),
        );
      });
    }

    testWidgets('0 pieces: the grey ring only, no arc', (tester) async {
      await _pump(tester, const PictureBadge(pieces: 0, asset: _asset));
      final ring = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PictureRingPainter,
      );
      expect(tester.renderObject(ring), isNot(paints..arc()));
    });
  });
}
