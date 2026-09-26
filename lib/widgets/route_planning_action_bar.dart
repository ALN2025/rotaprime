import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

/// Ações de planejamento: otimizar ou iniciar rota.
class RoutePlanningActionBar extends StatelessWidget {
  const RoutePlanningActionBar({
    super.key,
    required this.optimized,
    required this.isPro,
    required this.onOptimize,
    required this.onUseImportOrder,
    required this.onStart,
    required this.onRefine,
    required this.durationLabel,
    this.onAddManual,
  });

  final bool optimized;
  final bool isPro;
  final VoidCallback onOptimize;
  final VoidCallback onUseImportOrder;
  final VoidCallback onStart;
  final VoidCallback onRefine;
  final String durationLabel;
  /// Rota manual em montagem: botão para seguir adicionando paradas.
  final VoidCallback? onAddManual;

  @override
  Widget build(BuildContext context) {
    if (optimized && !isPro) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.format_list_numbered_rtl, color: Colors.white.withValues(alpha: 0.7), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Plano grátis: ordem da planilha · sem linha laranja no mapa',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onStart,
            style: primaryOrangeButtonStyle(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'INICIAR ROTA',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      );
    }

    if (optimized) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 340;
          final timeChip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, color: AppColors.successGreen, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    durationLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
          final startBtn = ElevatedButton(
            onPressed: onStart,
            style: primaryOrangeButtonStyle(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            child: const Text('INICIAR ROTA'),
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                timeChip,
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onRefine,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Refinar'),
                ),
                const SizedBox(height: 8),
                startBtn,
              ],
            );
          }
          return Row(
            children: [
              timeChip,
              const Spacer(),
              OutlinedButton(
                onPressed: onRefine,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Refinar'),
              ),
              const SizedBox(width: 10),
              startBtn,
            ],
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onAddManual != null) ...[
          OutlinedButton.icon(
            onPressed: onAddManual,
            icon: const Icon(Icons.add_location_alt_outlined, size: 22),
            label: const Text(
              'ADICIONAR ENTREGA',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.orange, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
          const SizedBox(height: 10),
        ],
        ElevatedButton.icon(
          onPressed: onOptimize,
          icon: Icon(isPro ? Icons.auto_graph_rounded : Icons.lock_outline, size: 22),
          label: Text(
            isPro ? 'OTIMIZAR ROTA' : 'OTIMIZAR ROTA (PRO)',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
          ),
          style: primaryOrangeButtonStyle(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ).copyWith(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (!isPro) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onUseImportOrder,
            icon: const Icon(Icons.format_list_numbered_rtl, size: 20),
            label: const Text('Ordem do romaneio (1 → N)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}
