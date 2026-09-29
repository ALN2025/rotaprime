import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/providers/app_shell_provider.dart';
import 'package:rota_prime/providers/conta_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/screens/app_shell_screen.dart';
import 'package:rota_prime/screens/finalizar_rota_screen.dart';
import 'package:rota_prime/utils/route_delivery_stats.dart';
import 'package:rota_prime/widgets/route_completed_celebration.dart';

/// Finaliza a rota sem exigir km (estilo Spok).
Future<void> finalizeRouteQuick(BuildContext context, WidgetRef ref) async {
  await ref.read(rotaProvider.notifier).finalizeRoute(kmFinal: 0);
  ref.invalidate(contaRotasProvider);
  if (!context.mounted) return;
  ref.read(rotaProvider.notifier).clearWorkingRoute();
  switchAppShellTab(ref, 1);
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AppShellScreen()),
    (r) => false,
  );
}

/// Confirma pendências → efeito Spok → finalizar rápido ou tela opcional de km/gastos.
Future<void> runSpokStyleRouteFinishFlow(
  BuildContext context,
  WidgetRef ref, {
  Future<void> Function()? onCopyStops,
}) async {
  final paradas = ref.read(rotaProvider).paradas;
  if (paradas.isEmpty) return;

  final pending = paradas.where((p) => !p.entregue && !p.falha).length;
  if (pending > 0) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        title: Text(
          'Ainda faltam $pending entrega${pending == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Deseja marcar a rota como finalizada mesmo assim?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar', style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }

  await showRouteCompletedCelebration(
    context,
    stopCount: RouteDeliveryStats.totalStops(paradas),
    packageCount: RouteDeliveryStats.totalPackages(paradas),
    onCopyStops: onCopyStops == null
        ? null
        : () {
            Navigator.of(context, rootNavigator: true).pop();
            onCopyStops();
          },
    onFinishNow: () async {
      Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await finalizeRouteQuick(context, ref);
    },
    onFinanceOptional: () async {
      Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FinalizarRotaScreen()),
      );
    },
  );
}
