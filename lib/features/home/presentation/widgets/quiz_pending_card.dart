import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'card_deck_wrapper.dart';
import 'reward_item.dart';

class QuizPendingCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final int points;
  final VoidCallback onStartQuiz;

  const QuizPendingCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.points,
    required this.onStartQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return CardDeckWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = (constraints.maxWidth * 0.98)
              .clamp(440.0, 510.0)
              .toDouble();

          return SizedBox(
            height: cardHeight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 48, 22, 0),
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
                                height: 1,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 7),
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
                            const SizedBox(height: 13),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFE7E7EF),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.assignment_outlined,
                                    color: Color(0xFFE29A22),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Pending: Quiz',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF777887),
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
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
                                color: const Color(0xFF777887),
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            RewardItem(
                              color: const Color(0xFFEAA43A),
                              icon: Icons.star_rounded,
                              text: '$points Points',
                            ),
                            const SizedBox(height: 10),
                            const RewardItem(
                              color: Color(0xFF28B36A),
                              icon: Icons.local_fire_department,
                              text: '1 streak',
                            ),
                            const SizedBox(height: 10),
                            const RewardItem(
                              color: Color(0xFF5B5BD6),
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
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 34),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onStartQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5BD6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Start Quiz',
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
