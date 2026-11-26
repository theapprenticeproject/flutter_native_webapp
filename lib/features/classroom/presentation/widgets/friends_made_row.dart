import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n.dart';

/// "See what friends made 👀" and three tiles (design M-S-01 and M-S-04). The
/// emoji are part of the design, not placeholders. A tap on the label or on a
/// tile opens the Gallery, where the real work of other students is (R-85).
class FriendsMadeRow extends StatelessWidget {
  const FriendsMadeRow({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _emoji = ['🐱', '🚀', '🌈'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              context.l10n.classSeeFriends,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.subheadingColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < _emoji.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  key: ValueKey('friend-tile-$i'),
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      _emoji[i],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
