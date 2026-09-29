import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/config/plan_limits.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/widgets/pro_gate.dart';
import 'package:rota_prime/utils/plan_sync_feedback.dart';
import 'package:rota_prime/widgets/pro_subscription_pay_buttons.dart';

/// Planos comercializados — Standard (completo) e Lite (desconto, menos recursos).
class ComparePlansScreen extends ConsumerStatefulWidget {
  const ComparePlansScreen({super.key});

  @override
  ConsumerState<ComparePlansScreen> createState() => _ComparePlansScreenState();
}

class _ComparePlansScreenState extends ConsumerState<ComparePlansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Comparar planos'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.orange,
          labelColor: AppColors.orange,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Standard'),
            Tab(text: 'Lite'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PlanTab(
            planName: 'Standard',
            description:
                'Desbloqueie todos os recursos do ROTA PRIME e termine seu trabalho mais cedo.',
            features: const [
              _PlanFeature('Otimize paradas ilimitadas por rota', included: true),
              _PlanFeature('Mapa escuro Google (nomes de ruas)', included: true),
              _PlanFeature('Traçado laranja e navegação pelas ruas (OSRM)', included: true),
              _PlanFeature('Inclua paradas por voz ou câmera', included: true),
              _PlanFeature('Vários romaneios na mesma rota (Magalog, Loggi, Shopee…)', included: true),
              _PlanFeature('Controle de gastos e lucro da rota', included: true),
              _PlanFeature('Refazer rota salva para testes de entrega', included: true),
            ],
            footer: _standardPlanFooter(context, ref, sub),
          ),
          _PlanTab(
            planName: 'Lite',
            description:
                'Versão Lite do ROTA PRIME com recursos essenciais por um valor menor.',
            features: [
              const _PlanFeature('Otimize paradas ilimitadas por rota', included: true),
              const _PlanFeature('Mapa, pins e ordem do romaneio', included: true),
              const _PlanFeature('Inclua paradas por voz ou câmera', included: false),
              const _PlanFeature('Traçado laranja / OSRM completo', included: false),
              const _PlanFeature('Controle de gastos avançado', included: false),
              _PlanFeature(
                'Trial ${PlanLimits.proTrialDays} dias na 1ª instalação',
                included: true,
              ),
            ],
            footer: _ActionFooter(
              label: 'Troque de plano · fale com o suporte',
              subtitle: 'Cancele ou faça upgrade quando quiser',
              onTap: () => showProActivationDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _standardPlanFooter(BuildContext context, WidgetRef ref, SubscriptionState sub) {
  if (sub.isLicensedPro) {
    return _SubscribedFooter(
      renewHint: sub.planStatusLine,
      price: 'ROTA PRIME PRO',
    );
  }
  if (sub.accessKind == PlanAccessKind.subscriptionPro) {
    return _SubscribedFooter(
      renewHint: sub.planStatusLine,
      price: 'PRO mensal',
    );
  }
  if (sub.isTrialActive) {
    return _ActionFooter(
      label: 'Continuar trial PRO',
      onTap: () => Navigator.pop(context),
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 8),
      Text(
        'Assinatura mensal no Mercado Pago (cartão ou Pix). '
        'Após pagar, toque em «Já paguei — sincronizar plano».',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 12),
      const ProSubscriptionPayButtons(compact: true),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () async {
          await ref.read(subscriptionProvider.notifier).reloadPlanFromServer(force: true);
          if (!context.mounted) return;
          final msg = await planSyncSnackBarMessage(ref);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orange),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('Já paguei — sincronizar plano'),
      ),
    ],
  );
}

class _PlanFeature {
  const _PlanFeature(this.label, {required this.included});
  final String label;
  final bool included;
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.planName,
    required this.description,
    required this.features,
    required this.footer,
  });

  final String planName;
  final String description;
  final List<_PlanFeature> features;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                planName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 20),
              for (final f in features) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      f.included ? Icons.check_circle : Icons.cancel_outlined,
                      size: 22,
                      color: f.included ? AppColors.successGreen : Colors.white24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f.label,
                        style: TextStyle(
                          color: f.included ? Colors.white : Colors.white38,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              footer,
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Política de privacidade · Termos de uso',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SubscribedFooter extends StatelessWidget {
  const _SubscribedFooter({required this.renewHint, required this.price});

  final String renewHint;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assinado',
                  style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800),
                ),
                Text(renewHint, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
