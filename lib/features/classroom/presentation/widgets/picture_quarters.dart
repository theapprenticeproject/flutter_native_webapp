import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Today's picture in 4 quarters (R-69; the design M-C03, M-C05 and M-C26b).
/// The first [pieces] quarters are open and show that part of the picture, in
/// reading order (top left, top right, bottom left, bottom right). The others
/// are closed, with a "?".
// shortcut: the reading order and the two colours of the closed quarters are
// read from the exported frames, not from the Figma file. Check them there.
class PictureQuarters extends StatelessWidget {
  const PictureQuarters({
    required this.asset,
    required this.pieces,
    this.circle = false,
    this.radius = 12,
    super.key,
  });

  /// The picture. Null, or one that does not load, shows a plain tile.
  final String? asset;
  final int pieces;

  /// Round, for the badge. Otherwise a rounded square.
  final bool circle;
  final double radius;

  static const _corners = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];
  static const _purple = Color(0xFF5B5BD6);
  static const _lavender = Color(0xFFE4E4FB);

  @override
  Widget build(BuildContext context) {
    final n = pieces.clamp(0, 4);
    final grid = AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = box.biggest.shortestSide;
          final half = side / 2;
          Widget quarter(int i) =>
              i < n ? _open(i, side, half) : _closed(i, half);
          return Column(
            children: [
              Row(children: [quarter(0), quarter(1)]),
              Row(children: [quarter(2), quarter(3)]),
            ],
          );
        },
      ),
    );
    return circle
        ? ClipOval(child: grid)
        : ClipRRect(borderRadius: BorderRadius.circular(radius), child: grid);
  }

  Widget _open(int i, double side, double half) {
    final image = asset == null
        ? const ColoredBox(color: _lavender)
        : Image.asset(
            asset!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: _lavender),
          );
    return SizedBox(
      key: ValueKey('quarter-$i-open'),
      width: half,
      height: half,
      // The whole picture is laid out at full size, then cut to this quarter.
      child: ClipRect(
        child: OverflowBox(
          alignment: _corners[i],
          minWidth: side,
          maxWidth: side,
          minHeight: side,
          maxHeight: side,
          child: SizedBox(width: side, height: side, child: image),
        ),
      ),
    );
  }

  Widget _closed(int i, double half) {
    // A checkerboard (design M-C03, M-C05): light, dark, dark, light.
    final dark = i == 1 || i == 2;
    return SizedBox(
      key: ValueKey('quarter-$i-closed'),
      width: half,
      height: half,
      child: ColoredBox(
        color: dark ? _purple : _lavender,
        child: Center(
          child: Text(
            '?',
            style: GoogleFonts.inter(
              fontSize: (half * 0.4).clamp(8, 32).toDouble(),
              fontWeight: FontWeight.w800,
              color: dark ? Colors.white : _purple,
            ),
          ),
        ),
      ),
    );
  }
}
