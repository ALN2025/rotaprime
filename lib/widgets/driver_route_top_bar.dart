import 'package:flutter/material.dart';
import 'package:rota_prime/widgets/circuit_view_toggle.dart';
import 'package:rota_prime/widgets/driver_route_stat_cards.dart';
import 'package:rota_prime/widgets/plan_status_badge.dart';
import 'package:rota_prime/widgets/spoke_widgets.dart';

/// Cabeçalho flutuante: menu · Mapa/Lista · cards de pacotes e tempo (sem logo).
class DriverRouteTopBar extends StatelessWidget {
  const DriverRouteTopBar({
    super.key,
    required this.view,
    required this.onViewChanged,
    required this.onMenu,
    required this.packagesDone,
    required this.packagesTotal,
    required this.routeActive,
    this.routeActiveSince,
    this.estimatedMinutes = 0,
    this.onAddParada,
    this.showViewToggle = true,
    this.showStatCards = true,
    this.showPlanBadge = false,
    this.compactHeader = false,
  });

  final CircuitDeliveryView view;
  final ValueChanged<CircuitDeliveryView> onViewChanged;
  final VoidCallback onMenu;
  final int packagesDone;
  final int packagesTotal;
  final bool routeActive;
  final DateTime? routeActiveSince;
  final int estimatedMinutes;
  final VoidCallback? onAddParada;
  final bool showViewToggle;
  final bool showStatCards;
  final bool showPlanBadge;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, compactHeader ? 2 : 4, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compactHeader)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MapCircleButton(icon: Icons.menu, onTap: onMenu),
                if (onAddParada != null) ...[
                  const SizedBox(width: 6),
                  MapAddDeliveryButton(onTap: onAddParada!),
                ],
                if (showViewToggle) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: CircuitViewToggle(
                        value: view,
                        onChanged: onViewChanged,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (showPlanBadge) const PlanStatusBadge(compact: true),
              ],
            )
          else ...[
            Row(
              children: [
                MapCircleButton(icon: Icons.menu, onTap: onMenu),
                const Spacer(),
                if (showPlanBadge) const PlanStatusBadge(compact: true),
              ],
            ),
            if (onAddParada != null || showViewToggle) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (onAddParada != null) ...[
                    MapAddDeliveryButton(onTap: onAddParada!),
                    if (showViewToggle) const SizedBox(width: 8),
                  ],
                  if (showViewToggle)
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: CircuitViewToggle(
                          value: view,
                          onChanged: onViewChanged,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
          if (showStatCards) ...[
            SizedBox(height: compactHeader ? 3 : 4),
            DriverRouteStatCards(
              packagesDone: packagesDone,
              packagesTotal: packagesTotal,
              routeActive: routeActive,
              routeActiveSince: routeActiveSince,
              estimatedMinutes: estimatedMinutes,
            ),
          ],
        ],
      ),
    );
  }
}
