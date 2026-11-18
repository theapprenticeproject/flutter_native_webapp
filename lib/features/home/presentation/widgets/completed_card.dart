import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import 'card_deck_wrapper.dart';
import 'reward_item.dart';

class CompletedCard extends StatelessWidget {
  final int points;
  final VoidCallback? onContinue;

  const CompletedCard({super.key, required this.points, this.onContinue});

  @override
  Widget build(BuildContext context) {
    return CardDeckWrapper(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 36, 26, 34),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final title = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeCongrats,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF747583),
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  onContinue != null
                      ? context.l10n.homeActivityComplete
                      : context.l10n.homeDoneForWeek,
                  textAlign: compact ? TextAlign.center : TextAlign.left,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1C1C21),
                    height: 1.04,
                    letterSpacing: 0,
                  ),
                ),
              ],
            );

            final rewards = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeKeepWinning,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF777887),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                RewardItem(
                  color: Color(0xFFEAA43A),
                  icon: Icons.star_rounded,
                  text: context.l10n.homePoints,
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                compact
                    ? Column(
                        children: [title, const SizedBox(height: 22), rewards],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: title),
                          const SizedBox(width: 24),
                          rewards,
                        ],
                      ),
                const SizedBox(height: 34),
                Text(
                  onContinue != null
                      ? context.l10n.homeReadyForNext
                      : context.l10n.homeSeeYouNextWeek,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF777887),
                    letterSpacing: 0,
                  ),
                ),
                if (onContinue != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      child: Text(context.l10n.homeLetsGo),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
