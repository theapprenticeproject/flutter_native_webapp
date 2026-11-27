import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/app_primary_button.dart';
import 'card_deck_wrapper.dart';

/// The one Home card of the design (Figma M-F2-01, "Activity card"): a thumbnail,
/// the title, a chip, and a primary button. Every Home state uses it, so the
/// start, the quiz, the send-project and the waiting cards look the same (QA:
/// "buttons and UI colours are inconsistent and do not match the design").
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
    this.thumbnailAsset,
    this.chip,
    this.body,
  });

  final String title;
  final String buttonLabel;
  final VoidCallback? onPressed;

  /// The activity's picture. Without one, or if it does not load, a grey tile.
  final String? thumbnailAsset;

  /// What is going on (an [ActivityChip]), under the title.
  final Widget? chip;

  /// A line of explanation under the chip (for example while waiting).
  final String? body;

  @override
  Widget build(BuildContext context) {
    return CardDeckWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The same height for every card (a card with an explanation is a
          // little taller). If a long text does not fit, the part between the
          // thumbnail and the button scrolls: the button never leaves the card.
          final height =
              (constraints.maxWidth * 0.98).clamp(440.0, 510.0).toDouble() +
              (body == null ? 0.0 : 110.0);
          final mediaHeight = (constraints.maxWidth * 0.36)
              .clamp(150.0, 182.0)
              .toDouble();
          final side = (constraints.maxWidth * 0.05).clamp(18.0, 22.0);
          final top = (constraints.maxWidth * 0.07).clamp(28.0, 34.0);

          return SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(side, top, side, 18),
                  child: Container(
                    key: const ValueKey('activity-thumb'),
                    height: mediaHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEF1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: thumbnailAsset == null
                        ? const _Placeholder()
                        : Image.asset(
                            thumbnailAsset!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _Placeholder(),
                          ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: side),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C1C21),
                            height: 1.02,
                            letterSpacing: 0,
                          ),
                        ),
                        if (chip != null) ...[
                          const SizedBox(height: 12),
                          chip!,
                        ],
                        if (body != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            body!,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.4,
                              color: const Color(0xFF3A3A45),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(side, 16, side, top),
                  child: AppPrimaryButton(
                    label: buttonLabel,
                    onPressed: onPressed,
                    tall: true,
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

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(Icons.image_outlined, color: Color(0xFFB9BBC8), size: 30),
  );
}

/// The chip of the design (Figma "Chips/gamification-points"): a light orange
/// pill with an orange icon and dark orange text.
class ActivityChip extends StatelessWidget {
  const ActivityChip({super.key, required this.text, this.icon, this.leading});

  /// An icon, or a [leading] widget (for example the points coin) instead.
  final IconData? icon;
  final Widget? leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('activity-chip'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEFD6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading ?? Icon(icon, size: 16, color: const Color(0xFFE8A13B)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9A5B00),
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
