import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The small badge on every screen of the activity: how many of the 4 pieces of
/// today's picture are unlocked (R-69).
class PictureBadge extends StatelessWidget {
  const PictureBadge({required this.pieces, this.onTap, super.key});

  final int pieces;

  /// Tapping the badge opens the picture.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = pieces.clamp(0, 4);
    return Semantics(
      label: "Today's picture, $n of 4 pieces",
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFFD),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 16,
                color: Color(0xFF5B5BD6),
              ),
              const SizedBox(width: 5),
              Text(
                '$n/4',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5B5BD6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
