import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The dashed frame around "Add my work" (design M-S-01). Red when the file was
/// wrong (M-S-05).
class DashedUploadBox extends StatelessWidget {
  const DashedUploadBox({super.key, required this.child, this.error = false});

  final Widget child;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(error: error),
      child: Container(
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFBE9E7) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.error});

  final bool error;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = error ? AppTheme.dangerText : const Color(0xFFB9B3F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.error != error;
}
