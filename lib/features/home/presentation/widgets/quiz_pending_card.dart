import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import 'card_deck_wrapper.dart';
import '../../../../shared/widgets/app_primary_button.dart';

class QuizPendingCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final VoidCallback onStartQuiz;

  const QuizPendingCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
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
                              context.l10n.homeCourseLabel(courseDisplay),
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
                                    context.l10n.homePendingQuiz,
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
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 34),
                  child: AppPrimaryButton(
                    label: context.l10n.homeStartQuiz,
                    onPressed: onStartQuiz,
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
