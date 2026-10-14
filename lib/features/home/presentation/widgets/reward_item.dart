import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const RewardItem({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isGem = icon == Icons.diamond_rounded;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isGem ? Colors.transparent : color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isGem ? color : Colors.white,
            size: isGem ? 22 : 12,
          ),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 92),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF676977),
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
