import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'card_deck_wrapper.dart';
import 'reward_item.dart';

class SendProjectCard extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final int points;
  final VoidCallback onSend;

  const SendProjectCard({
    super.key,
    required this.courseDisplay,
    required this.unitName,
    required this.points,
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
                    points: points,
                    badge: _TaskBadge(
                      icon: Icons.info_outline_rounded,
                      text: 'To do: Send project',
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
                        'Send my project',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 26),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Send in '),
                        TextSpan(
                          text: '2days 15hrs',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF28B36A),
                          ),
                        ),
                        const TextSpan(text: ' and earn '),
                        TextSpan(
                          text: 'extra 2💎',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF5B5BD6),
                          ),
                        ),
                      ],
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1C1C21),
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

class _CardBody extends StatelessWidget {
  final String courseDisplay;
  final String unitName;
  final int points;
  final Widget badge;

  const _CardBody({
    required this.courseDisplay,
    required this.unitName,
    required this.points,
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
              badge,
            ],
          ),
        ),
        const SizedBox(width: 16),
        _Rewards(points: points),
      ],
    );
  }
}

class _Rewards extends StatelessWidget {
  final int points;

  const _Rewards({required this.points});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
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
