import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reward_item.dart';
import 'card_deck_wrapper.dart';

class StartActivityCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final String thumbnailAsset;
  final int points;
  final VoidCallback? onStart;

  const StartActivityCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.thumbnailAsset,
    required this.points,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return CardDeckWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = (constraints.maxWidth * 0.98)
              .clamp(440.0, 510.0)
              .toDouble();
          final mediaHeight = (constraints.maxWidth * 0.36)
              .clamp(150.0, 182.0)
              .toDouble();
          final buttonHeight = (constraints.maxWidth * 0.12)
              .clamp(52.0, 58.0)
              .toDouble();
          final horizontalPadding = (constraints.maxWidth * 0.05)
              .clamp(18.0, 22.0)
              .toDouble();
          final topPadding = (constraints.maxWidth * 0.07)
              .clamp(28.0, 34.0)
              .toDouble();
          final bottomPadding = (constraints.maxWidth * 0.07)
              .clamp(28.0, 34.0)
              .toDouble();

          return SizedBox(
            height: cardHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    18,
                  ),
                  child: Container(
                    height: mediaHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE8E8EC),
                        width: 8,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      thumbnailAsset,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Color(0xFFB9BBC8),
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Core $courseDisplay 1',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF747583),
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              unitName,
                              style: GoogleFonts.inter(
                                fontSize: 27,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1C1C21),
                                height: 1.02,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 112),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You'll earn",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8E8E9F),
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RewardItem(
                              color: const Color(0xFFF5B041),
                              icon: Icons.star_rounded,
                              text: '$points Points',
                            ),
                            const SizedBox(height: 8),
                            RewardItem(
                              color: const Color(0xFF2ECC71),
                              icon: Icons.local_fire_department,
                              text: '1 streak',
                            ),
                            const SizedBox(height: 8),
                            RewardItem(
                              color: const Color(0xFF5B5BD6),
                              icon: Icons.diamond_rounded,
                              text: '1 skill gem',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5BD6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        onStart == null
                            ? 'Weekly limit reached'
                            : 'Start Activity',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
