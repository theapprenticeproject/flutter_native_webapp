import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/friends_made_row.dart';

/// Design M-S-01 and M-S-04: under the prompt, "See what friends made 👀" and
/// three tiles with 🐱 🚀 🌈. They are part of the design, not placeholders.
void main() {
  testWidgets('the label and the three emoji tiles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FriendsMadeRow(onTap: () {})),
      ),
    );
    expect(find.text('See what friends made 👀'), findsOneWidget);
    for (final e in ['🐱', '🚀', '🌈']) {
      expect(find.text(e), findsOneWidget);
    }
  });

  testWidgets('a tap on the label or on a tile opens the Gallery', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FriendsMadeRow(onTap: () => taps++)),
      ),
    );
    await tester.tap(find.text('See what friends made 👀'));
    await tester.tap(find.text('🚀'));
    expect(taps, 2);
  });

  testWidgets('the three tiles have the same width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 330, child: FriendsMadeRow(onTap: () {})),
        ),
      ),
    );
    final sizes = [
      for (final e in ['🐱', '🚀', '🌈'])
        tester
            .getSize(
              find
                  .ancestor(of: find.text(e), matching: find.byType(InkWell))
                  .first,
            )
            .width,
    ];
    expect(sizes.toSet().length, 1);
  });

  // Figma: the tiles are 101 x 72 in a 319 wide card, 8 apart. They looked flat
  // (about 100 x 44) when they were made 44 high.
  testWidgets('the tiles are 72 high, about 1.4 times as wide, 8 apart', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 319, child: FriendsMadeRow(onTap: () {})),
          ),
        ),
      ),
    );
    Size tile(String e) => tester.getSize(
      find.ancestor(of: find.text(e), matching: find.byType(InkWell)).first,
    );
    expect(tile('🐱').height, 72);
    expect(tile('🐱').width, closeTo(101, 0.5));
    final gap =
        tester.getTopLeft(find.byKey(const ValueKey('friend-tile-1'))).dx -
        tester.getTopRight(find.byKey(const ValueKey('friend-tile-0'))).dx;
    expect(gap, 8);
  });
}
