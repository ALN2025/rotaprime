import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/utils/route_delivery_stats.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';
import 'package:rota_prime/widgets/circuit_stop_ui.dart';
import 'package:rota_prime/widgets/carrier_pin_badge.dart';
import 'package:rota_prime/widgets/prazo_entrega_highlight.dart';

/// Linha da lista de paradas — arrastar ← entregue (verde), → não entregue (vermelho).
class CircuitSlidableStopRow extends StatelessWidget {
  const CircuitSlidableStopRow({
    super.key,
    required this.parada,
    required this.allParadas,
    this.totalPackages,
    required this.onTap,
    required this.onDelivered,
    required this.onFailed,
    this.isNextHighlight = false,
    this.enableSwipe = true,
  });

  final Parada parada;
  final List<Parada> allParadas;
  final int? totalPackages;
  final VoidCallback onTap;
  final VoidCallback onDelivered;
  final VoidCallback onFailed;
  final bool isNextHighlight;
  /// No painel do mapa, swipe sobrepõe o cabeçalho da parada — desligado.
  final bool enableSwipe;

  Widget _rowContent() {
    return Material(
      color: isNextHighlight
          ? AppColors.orange.withValues(alpha: 0.14)
          : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isNextHighlight ? AppColors.orange : Colors.white12,
              width: isNextHighlight ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              _StopNumberBadge(
                parada: parada,
                allParadas: allParadas,
                large: isNextHighlight,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNextHighlight)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'PRÓXIMA PARADA',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    Text(
                      parada.destinationAddress,
                      maxLines: isNextHighlight ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isNextHighlight ? 15 : 13,
                        fontWeight: isNextHighlight ? FontWeight.w700 : FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ParadaLabels.deliveryListSubtitle(
                        allParadas,
                        parada,
                        totalPackages: totalPackages ??
                            RouteDeliveryStats.totalPackages(allParadas),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isNextHighlight ? Colors.white70 : Colors.white54,
                        fontSize: isNextHighlight ? 12 : 11,
                        height: 1.2,
                      ),
                    ),
                    if (RomaneioCarrierBranding.showsDeliveryBadgeForParada(parada) ||
                        parada.prazoEntrega.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (RomaneioCarrierBranding.showsDeliveryBadgeForParada(parada))
                            CarrierDeliveryBadge(parada: parada, compact: true),
                          if (parada.prazoEntrega.trim().isNotEmpty)
                            PrazoEntregaHighlight(
                              prazo: parada.prazoEntrega,
                              compact: true,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!ParadaLabels.routeUsesUnifiedPinOrder(allParadas)) ...[
                const SizedBox(width: 6),
                PackageOrderBadge(
                  parada: parada,
                  allParadas: allParadas,
                  compact: !isNextHighlight,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enableSwipe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _rowContent(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Slidable(
        key: ValueKey(parada.id),
        groupTag: 'delivery-upcoming-stops',
        // Arrastar ← = entregue (end) · arrastar → = não entregue (start)
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.38,
          children: [
            SlidableAction(
              onPressed: (_) => onFailed(),
              backgroundColor: AppColors.stopFailed,
              foregroundColor: Colors.white,
              icon: Icons.close_rounded,
              label: 'Não entregue',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.38,
          children: [
            SlidableAction(
              onPressed: (_) => onDelivered(),
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              icon: Icons.check_rounded,
              label: 'Entregue',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: _rowContent(),
      ),
    );
  }
}

class _StopNumberBadge extends StatelessWidget {
  const _StopNumberBadge({
    required this.parada,
    required this.allParadas,
    required this.large,
  });

  final Parada parada;
  final List<Parada> allParadas;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final label = ParadaLabels.mapPinLabel(allParadas, parada);
    final size = large ? 46.0 : 36.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: large ? AppColors.orange : AppColors.orange.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: large ? 3 : 2),
        boxShadow: large
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: large ? 16 : 13,
        ),
      ),
    );
  }
}
