import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

/// Puck do entregador — círculo laranja + seta de direção (sem triângulo grande).
class RotaDriverMapMarker extends StatelessWidget {
  const RotaDriverMapMarker({super.key, required this.navigationMode});

  final bool navigationMode;

  @override
  Widget build(BuildContext context) {
    final size = navigationMode ? 48.0 : 36.0;
    final iconSize = navigationMode ? 26.0 : 20.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orange,
        border: Border.all(
          color: Colors.white,
          width: navigationMode ? 3.5 : 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.navigation_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}
