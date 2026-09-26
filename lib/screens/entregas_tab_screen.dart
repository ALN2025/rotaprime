import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/rota.dart';
import 'package:rota_prime/providers/app_shell_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/utils/route_delivery_stats.dart';
import 'package:rota_prime/widgets/app_shell_bootstrap.dart';
import 'package:rota_prime/widgets/continue_delivery_banner.dart';
import 'package:rota_prime/screens/route_delivery_ledger_screen.dart';
import 'package:rota_prime/widgets/circuit_slidable_stop_row.dart';
import 'package:rota_prime/services/spreadsheet_picker.dart';

/// Aba **Entregas** — mesma lista do modo Mapa/Lista (pin + Magalog/Loggi).
class EntregasTabScreen extends ConsumerWidget {
  const EntregasTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rotaProvider);
    final rota = state.rota;
    final paradas = List<Parada>.from(state.paradas)
      ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
    final imported = rota?.pacotesImportados ?? 0;
    final totalPkgs = RouteDeliveryStats.packageDenominator(
      paradas,
      importedTotal: imported > 0 ? imported : null,
    );

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppShellTitleRow(title: 'Entregas'),
            if (rota != null && rota.status == RotaStatus.ativa) ...[
              ContinueDeliveryBanner(
                rota: rota,
                onContinue: () => navigateToActiveDelivery(context, ref),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RouteDeliveryLedgerScreen(
                          onOpenOnMap: (p) {
                            Navigator.of(context).pop();
                            ref.read(mapFocusParadaIdProvider.notifier).state = p.id;
                            navigateToActiveDelivery(context, ref);
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check_outlined, color: AppColors.orange),
                  label: const Text(
                    'Entregues e não entregues',
                    style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.orange),
                  ),
                ),
              ),
            ],
            if (paradas.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma rota carregada.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Importe um romaneio em Rotas ou no Mapa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: () => switchAppShellTab(ref, 1),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.orange,
                            side: const BorderSide(color: AppColors.orange),
                          ),
                          child: const Text('Ir para Rotas'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rota?.titulo ?? 'Rota atual',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14),
                      ),
                    ),
                    Text(
                      '$totalPkgs pacotes',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  itemCount: paradas.length,
                  itemBuilder: (context, i) {
                    final p = paradas[i];
                    return CircuitSlidableStopRow(
                      parada: p,
                      allParadas: paradas,
                      totalPackages: totalPkgs,
                      enableSwipe: false,
                      onTap: () {
                        ref.read(mapFocusParadaIdProvider.notifier).state = p.id;
                        navigateToActiveDelivery(context, ref);
                      },
                      onDelivered: () =>
                          ref.read(rotaProvider.notifier).markEntregue(p.id, entregue: true),
                      onFailed: () => ref.read(rotaProvider.notifier).markEntregue(
                            p.id,
                            entregue: false,
                            falha: true,
                          ),
                    );
                  },
                ),
              ),
              if (rota != null && rota.status == RotaStatus.rascunho) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: OutlinedButton.icon(
                    onPressed: () => pickSpreadsheetAndMergeIntoRoute(ref),
                    icon: const Icon(Icons.library_add_outlined),
                    label: const Text('Adicionar outro romaneio'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orange,
                      side: const BorderSide(color: AppColors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ElevatedButton(
                  onPressed: () => switchAppShellTab(ref, 0),
                  style: primaryOrangeButtonStyle(),
                  child: const Text('VER NO MAPA'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
