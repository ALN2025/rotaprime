import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/config/plan_limits.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/screens/compare_plans_screen.dart';
import 'package:rota_prime/services/mercadopago_checkout_launcher.dart';
import 'package:rota_prime/utils/plan_sync_feedback.dart';

Future<bool> ensureProOrPrompt(BuildContext context, WidgetRef ref, {String? feature}) async {
  if (ref.read(subscriptionProvider).isPro) return true;
  await showProActivationDialog(context, ref, feature: feature);
  return ref.read(subscriptionProvider).isPro;
}

/// Diálogo público: assinatura Mercado Pago (sem chave / vitalício).
Future<void> showProActivationDialog(
  BuildContext context,
  WidgetRef ref, {
  String? feature,
}) async {
  final featureLine = feature != null ? '\n\nRecurso: $feature' : '';

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppColors.sheet,
        title: const Text('ROTA PRIME PRO', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Este recurso faz parte do plano PRO.$featureLine\n\n'
              'Grátis: até ${PlanLimits.freeMaxDeliveriesPerRoute} entregas por rota. '
              'PRO mensal R\$ ${PlanLimits.proMonthlyPriceBrl.toStringAsFixed(0)}: rotas ilimitadas, '
              'otimização OSRM e mapa escuro.\n\n'
              'Após pagar no Mercado Pago, toque em «Já paguei — sincronizar» ou '
              'Configurações → Sincronizar plano.',
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openMercadoPagoSubscriptionCheckout(context, pix: false);
              },
              child: Text(
                'Assinar cartão R\$ ${PlanLimits.proMonthlyPriceBrl.toStringAsFixed(0)}/mês',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openMercadoPagoSubscriptionCheckout(context, pix: true);
              },
              child: Text(
                'Assinar Pix R\$ ${PlanLimits.proMonthlyPriceBrl.toStringAsFixed(0)}/mês',
              ),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(subscriptionProvider.notifier).reloadPlanFromServer(force: true);
                if (!ctx.mounted) return;
                if (ref.read(subscriptionProvider).isPro) {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PRO ativo')),
                    );
                  }
                } else {
                  final msg = await planSyncSnackBarMessage(ref);
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
                  );
                }
              },
              child: const Text('Já paguei — sincronizar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComparePlansScreen()),
                );
              },
              child: const Text('Comparar planos'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      );
    },
  );
}
