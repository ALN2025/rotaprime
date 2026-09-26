import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

/// Logo ROTA PRIME — usa `assets/LOGO.png` quando existir.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 52,
    this.preferVector = false,
  });

  final double height;

  /// Se true, desenho vetorial (fallback). Por padrão prioriza o PNG real.
  final bool preferVector;

  @override
  Widget build(BuildContext context) {
    if (preferVector) {
      return _BrandLogoVector(height: height);
    }
    return Image.asset(
      'assets/LOGO.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => _BrandLogoVector(height: height),
    );
  }
}

class _BrandLogoVector extends StatelessWidget {
  const _BrandLogoVector({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final scale = height / 52;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ShieldMark(size: 40 * scale),
        SizedBox(width: 10 * scale),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ROTA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20 * scale,
                height: 0.95,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'PRIME',
              style: TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w900,
                fontSize: 20 * scale,
                height: 1,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShieldMark extends StatelessWidget {
  const _ShieldMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShieldPainter(),
        child: Center(
          child: Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: size * 0.48,
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.92, h * 0.22)
      ..lineTo(w * 0.88, h * 0.58)
      ..quadraticBezierTo(w * 0.5, h * 1.02, w * 0.12, h * 0.58)
      ..lineTo(w * 0.08, h * 0.22)
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF8A3D),
          AppColors.orange,
          const Color(0xFFE65100),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
