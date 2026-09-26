import 'package:flutter/material.dart';

/// Ícone tracejado “+ paradas” do empty state.
class EmptyStopsIllustration extends StatelessWidget {
  const EmptyStopsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(56, 56),
      painter: _DashedBoxPainter(),
      child: const Center(
        child: Icon(Icons.add, color: Colors.white38, size: 28),
      ),
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 6.0;
    const gap = 4.0;
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8));
    _drawDashedRRect(canvas, r, paint, dash, gap);
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint, double dash, double gap) {
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
