import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/reveal_asset_resolver.dart';
import 'picture_quarters.dart';

/// The round badge on every screen of the activity: today's picture in 4
/// quarters, one more open for each step finished, with the "n/4" pill (R-69,
/// the design M-C03 and M-C05). Tapping it opens the picture.
class PictureBadge extends StatelessWidget {
  const PictureBadge({
    required this.pieces,
    this.unitIndex = 0,
    this.asset,
    this.onTap,
    super.key,
  });

  final int pieces;

  /// Which picture: the one of this unit. Ignored when [asset] is given.
  final int unitIndex;
  final String? asset;

  /// Tapping the badge opens the picture.
  final VoidCallback? onTap;

  static const _purple = Color(0xFF5B5BD6);

  /// The badge floats at the bottom right (design M-C03). The chat list ends
  /// with [clearance] of room, so the last item (the Confirm button) can be
  /// scrolled up above it.
  static const double size = 64;
  static const double margin = 16;
  static const double clearance = size + margin + 16;

  @override
  Widget build(BuildContext context) {
    final n = pieces.clamp(0, 4);
    return Semantics(
      label: context.l10n.classPictureSemantics(n),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  // The ring (design M-C05): a grey track with a purple arc
                  // over it, a quarter for each open piece.
                  child: CustomPaint(
                    painter: PictureRingPainter(progress: n / 4),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        PictureRingPainter.width + 3,
                      ),
                      child: asset != null
                          ? PictureQuarters(
                              asset: asset,
                              pieces: n,
                              circle: true,
                            )
                          : FutureBuilder<String>(
                              future: RevealAssetResolver.resolve(unitIndex),
                              builder: (context, snapshot) => PictureQuarters(
                                asset: snapshot.data,
                                pieces: n,
                                circle: true,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _purple,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$n/4',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ring around the badge: a grey track, and over it a purple arc that starts
/// at 12 o'clock and runs clockwise for [progress] (0 to 1) of the circle.
class PictureRingPainter extends CustomPainter {
  const PictureRingPainter({required this.progress});

  final double progress;

  static const double width = 5;
  static const _track = Color(0xFFD6D6DC);
  static const _arc = Color(0xFF5B5BD6);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    canvas.drawCircle(
      rect.center,
      rect.shortestSide / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = _track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      progress.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = _arc,
    );
  }

  @override
  bool shouldRepaint(PictureRingPainter old) => old.progress != progress;
}
