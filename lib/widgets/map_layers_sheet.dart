import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/widgets/pro_gate.dart';
import 'package:rota_prime/widgets/spoke_widgets.dart';

Future<void> showMapLayersSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(mapSettingsProvider).basemap;
          final isPro = ref.watch(subscriptionProvider.select((s) => s.isPro));
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetDragHandle(),
                  const Text(
                    'Tipo de mapa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    switch (ref.watch(subscriptionProvider.select((s) => s.accessKind))) {
                      PlanAccessKind.free =>
                        'Grátis: apenas Ruas (Google Maps).',
                      PlanAccessKind.trialPro =>
                        'Trial: escolha Ruas ou Escuro. Google Maps · nomes nativos.',
                      _ =>
                        'PRO: mapa Escuro ao abrir (pode mudar aqui). Google Maps · nomes nativos.',
                    },
                    style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  ...MapBasemap.userChoices.map((b) {
                    final selected = b == current;
                    final isDark = b == MapBasemap.dark;
                    final label = b == MapBasemap.streets ? 'Ruas' : 'Escuro';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? AppColors.orange : Colors.white38,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              b == MapBasemap.streets ? '$label ★' : label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: b == MapBasemap.streets ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isDark) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.orange.withValues(alpha: 0.6)),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: isDark
                          ? Text(
                              isPro ? 'Estilo escuro Google' : 'Ative PRO ou use o trial',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            )
                          : null,
                      onTap: () async {
                        if (MapBasemap.requiresPro(b) && !isPro) {
                          final ok = await ensureProOrPrompt(
                            context,
                            ref,
                            feature: 'Mapa escuro (Google)',
                          );
                          if (!ok || !context.mounted) return;
                        }
                        ref.read(mapSettingsProvider.notifier).setBasemap(b);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Mapa: ${b.userChoiceLabel} (Google Maps)'),
                            ),
                          );
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
