import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/platform/app_lifecycle_bridge.dart';
import 'package:rota_prime/screens/finalizar_rota_screen.dart';

typedef DeliveryMenuAction = Future<void> Function();

Future<void> showDeliveryRunMenuSheet(
  BuildContext context,
  WidgetRef ref, {
  required DeliveryMenuAction onExitToPlanning,
  VoidCallback? onReoptimize,
  VoidCallback? onOpenDeliveryLedger,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.sheet,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'O que você quer fazer?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _BigMenuButton(
              icon: Icons.phone_android,
              label: 'Usar Waze ou outro app',
              subtitle: 'Minimiza o ROTA PRIME — ao voltar, o mapa continua onde parou.',
              color: AppColors.orange,
              onTap: () {
                Navigator.pop(ctx);
                unawaited(AppLifecycleBridge.minimizeToBackground());
              },
            ),
            if (onOpenDeliveryLedger != null) ...[
              const SizedBox(height: 10),
              _BigMenuButton(
                icon: Icons.fact_check_outlined,
                label: 'Entregues e não entregues',
                subtitle: 'Lista completa — desfazer status só com confirmação',
                color: AppColors.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  onOpenDeliveryLedger();
                },
              ),
            ],
            const SizedBox(height: 10),
            _BigMenuButton(
              icon: Icons.check_circle_outline,
              label: 'Terminei as entregas',
              subtitle: 'Encerrar o dia e ver o resumo',
              color: AppColors.successGreen,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FinalizarRotaScreen()),
                );
              },
            ),
            if (onReoptimize != null) ...[
              const SizedBox(height: 10),
              _BigMenuButton(
                icon: Icons.route,
                label: 'Reotimizar rota',
                subtitle: 'Recalcula a ordem das paradas — você continua entregando',
                color: AppColors.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  onReoptimize();
                },
              ),
            ],
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await onExitToPlanning();
              },
              icon: const Icon(Icons.edit_road, color: Colors.white54, size: 20),
              label: const Text(
                'Voltar a ajustar a rota',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BigMenuButton extends StatelessWidget {
  const _BigMenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.9)),
            ],
          ),
        ),
      ),
    );
  }
}
