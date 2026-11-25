import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'card_deck_wrapper.dart';
import '../../../../shared/widgets/app_primary_button.dart';

class StartActivityCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final String thumbnailAsset;
  final VoidCallback? onStart;

  const StartActivityCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.thumbnailAsset,
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
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
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
                              unitName,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C1C21),
                                height: 1.02,
                                letterSpacing: 0,
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
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: AppPrimaryButton(
                    label: onStart == null
                        ? context.l10n.homeWeeklyLimit
                        : context.l10n.homeStartActivity,
                    onPressed: onStart,
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
