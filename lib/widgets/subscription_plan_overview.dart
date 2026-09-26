import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/config/plan_limits.dart';
import 'package:rota_prime/providers/subscription_provider.dart' show PlanAccessKind, SubscriptionState;

/// Resumo Grátis vs PRO na tela Assinatura.
class SubscriptionPlanOverview extends StatelessWidget {
  const SubscriptionPlanOverview({super.key, required this.sub});

  final SubscriptionState sub;

  @override
  Widget build(BuildContext context) {
    final max = PlanLimits.freeMaxDeliveriesPerRoute;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                switch (sub.accessKind) {
                  PlanAccessKind.licensedPro => 'Seu plano: PRO',
                  PlanAccessKind.trialPro => 'Seu plano: Trial PRO (${sub.trialDaysRemaining}d)',
                  PlanAccessKind.free => 'Seu plano: Grátis',
                },
                style: TextStyle(
                  color: sub.isPro ? AppColors.orange : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              _bullet(
                icon: Icons.check_circle_outline,
                color: AppColors.successGreen,
                text:
                    'Grátis: até $max entregas por rota (planilha ou manual), mapa, entregas e ordem do romaneio.',
              ),
              const SizedBox(height: 6),
              _bullet(
                icon: Icons.star_outline,
                color: AppColors.orange,
                text:
                    'PRO (pagamento único por aparelho): rotas ilimitadas, otimização, linha laranja, reotimizar, gastos.',
              ),
              const SizedBox(height: 6),
              _bullet(
                icon: Icons.timer_outlined,
                color: const Color(0xFF5EEAD4),
                text:
                    'Trial: ${PlanLimits.proTrialDays} dias PRO por aparelho (ID). '
                    'Reinstalar só volta a Trial se o suporte liberar seu ID na lista online.',
              ),
              _bullet(
                icon: Icons.support_agent_outlined,
                color: Colors.white54,
                text:
                    'Suporte: todos usam o WhatsApp; PRO licenciado tem prioridade na fila.',
              ),
              if (!sub.isLicensedPro) ...[
                const SizedBox(height: 8),
                Text(
                  'PRO neste aparelho: copie o ID abaixo, envie pelo WhatsApp do suporte e cole a chave recebida.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
