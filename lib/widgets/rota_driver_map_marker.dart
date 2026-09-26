import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

/// Ícone do entregador no mapa — laranja ROTA PRIME + seta de direção (não usa caminhão genérico).
class RotaDriverMapMarker extends StatelessWidget {
  const RotaDriverMapMarker({super.key, required this.navigationMode});

  /// Modo condução: puck maior; mapa normal: compacto.
  final bool navigationMode;

  @override
  Widget build(BuildContext context) {
    final size = navigationMode ? 48.0 : 36.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RotaDriverPuckPainter(navigationMode: navigationMode),
      ),
    );
  }
}

class _RotaDriverPuckPainter extends CustomPainter {
  _RotaDriverPuckPainter({required this.navigationMode});

  final bool navigationMode;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 2), r * 0.92, shadow);

    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = navigationMode ? 3.5 : 3;
    final fill = Paint()..color = AppColors.orange;
    canvas.drawCircle(center, r * 0.88, fill);
    canvas.drawCircle(center, r * 0.88, ring);

    final inner = Paint()
      ..color = const Color(0xFFE85D00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, r * 0.55, inner);

    _drawDirectionArrow(canvas, center, r);
  }

  /// Seta apontando para cima (rotação do mapa vem do Transform.rotate no pai).
  void _drawDirectionArrow(Canvas canvas, Offset center, double r) {
    final scale = navigationMode ? 1.0 : 0.82;
    final tipY = center.dy - r * 0.42 * scale;
    final baseY = center.dy + r * 0.12 * scale;
    final halfW = r * 0.28 * scale;

    final arrow = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - halfW, baseY)
      ..lineTo(center.dx - halfW * 0.35, baseY)
      ..lineTo(center.dx - halfW * 0.35, baseY + r * 0.18 * scale)
      ..lineTo(center.dx + halfW * 0.35, baseY + r * 0.18 * scale)
      ..lineTo(center.dx + halfW * 0.35, baseY)
      ..lineTo(center.dx + halfW, baseY)
      ..close();

    canvas.drawPath(
      arrow,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    final dotR = r * 0.09 * scale;
    canvas.drawCircle(
      Offset(center.dx, baseY + r * 0.26 * scale),
      dotR,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _RotaDriverPuckPainter oldDelegate) =>
      oldDelegate.navigationMode != navigationMode;
}
