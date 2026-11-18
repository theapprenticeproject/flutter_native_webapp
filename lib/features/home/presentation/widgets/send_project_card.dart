import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

import 'card_deck_wrapper.dart';

class SendProjectCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final VoidCallback onSend;

  const SendProjectCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.onSend,
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
                  child: _CardBody(
                    courseDisplay: courseDisplay,
                    unitName: unitName,
                    badge: _TaskBadge(
                      icon: Icons.info_outline_rounded,
                      text: context.l10n.homeToDoSend,
                      background: const Color(0xFFFFF2D5),
                      color: const Color(0xFF9E6C00),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5BD6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        context.l10n.homeSendProject,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final Widget badge;

  const _CardBody({
    required this.courseDisplay,
    required this.unitName,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
              badge,
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color color;

  const _TaskBadge({
    required this.icon,
    required this.text,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
