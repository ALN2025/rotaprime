import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/config/plan_limits.dart';
import 'package:rota_prime/providers/subscription_provider.dart';

import 'package:rota_prime/screens/compare_plans_screen.dart';



Future<bool> ensureProOrPrompt(BuildContext context, WidgetRef ref, {String? feature}) async {

  if (ref.read(subscriptionProvider).isPro) return true;

  await showProActivationDialog(context, ref, feature: feature);

  return ref.read(subscriptionProvider).isPro;

}



Future<void> showProActivationDialog(

  BuildContext context,

  WidgetRef ref, {

  String? feature,

}) async {

  final ctrl = TextEditingController();

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
              'Grátis: até ${PlanLimits.freeMaxDeliveriesPerRoute} entregas por rota (planilha ou parada manual). '
              'PRO: rotas ilimitadas, otimização OSRM e licença neste aparelho.',
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),

            const SizedBox(height: 16),

            TextField(

              controller: ctrl,

              autocorrect: false,

              maxLines: 4,

              minLines: 2,

              style: const TextStyle(color: Colors.white, fontSize: 12),

              decoration: const InputDecoration(

                labelText: 'Licença PRO',

                labelStyle: TextStyle(color: Colors.white54),

                hintText: 'Chave com traços (XXXX-XXXX…) enviada pelo suporte',

                hintStyle: TextStyle(color: Colors.white24),

                alignLabelWithHint: true,

              ),

            ),

            const SizedBox(height: 8),

            TextButton.icon(

              onPressed: () async {

                final data = await Clipboard.getData(Clipboard.kTextPlain);

                final text = data?.text;

                if (text != null && text.trim().isNotEmpty) {

                  ctrl.text = text.trim();

                }

              },

              icon: const Icon(Icons.content_paste, size: 18),

              label: const Text('Colar chave'),

            ),

            const SizedBox(height: 8),

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

          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),

          ElevatedButton(

            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),

            onPressed: () async {

              final result =

                  await ref.read(subscriptionProvider.notifier).tryActivateLicense(ctrl.text);

              if (!ctx.mounted) return;

              if (result.ok) {

                Navigator.pop(ctx);

                if (context.mounted) {

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(content: Text('PRO ativado neste aparelho!')),

                  );

                }

              } else {

                ScaffoldMessenger.of(ctx).showSnackBar(

                  SnackBar(content: Text(result.error ?? 'Licença inválida')),

                );

              }

            },

            child: const Text('Ativar'),

          ),

        ],

      );

    },

  );

  ctrl.dispose();

}


