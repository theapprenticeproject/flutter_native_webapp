import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../domain/learning_progress/home_dashboard_provider.dart';
import 'card_deck_wrapper.dart';

/// The work is sent and the student waits for feedback (R-4, R-68). There is
/// nothing to do, so the card has only "Check again", which asks the Worker.
class SubmissionPendingCard extends ConsumerWidget {
  const SubmissionPendingCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.slow,
    this.ready = false,
    this.onOpen,
  });

  final String courseDisplay;
  final String unitName;

  /// Feedback is taking longer than expected (24 hours, A13).
  final bool slow;

  /// The feedback is valid and waiting to be seen (R-68): the button opens it.
  final bool ready;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardDeckWrapper(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 48, 22, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Core $courseDisplay 1',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF747583),
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
              ),
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE7E7EF)),
              ),
              child: Text(
                ready ? 'Feedback ready' : 'Pending: Feedback',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF777887),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              ready
                  ? 'Your feedback is ready! Tap to see what I think.'
                  : slow
                  ? 'Your feedback is taking longer than expected. '
                        'Please check again a little later.'
                  : "I'm looking at your work. Please wait, "
                        'and come back later to see my feedback.\n\n'
                        'Points will be provided after feedback.',
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.4,
                color: const Color(0xFF3A3A45),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: ready
                    ? onOpen
                    : () => ref.invalidate(learningDashboardProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5BD6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  ready ? 'See feedback' : 'Check again',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
