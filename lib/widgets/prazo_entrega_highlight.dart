import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

/// Prazo do romaneio (Loggi etc.) — sempre visível quando preenchido.
class PrazoEntregaHighlight extends StatelessWidget {
  const PrazoEntregaHighlight({
    super.key,
    required this.prazo,
    this.compact = false,
  });

  final String prazo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = prazo.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.85), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: AppColors.orange,
            size: compact ? 20 : 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prazo de entrega',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
