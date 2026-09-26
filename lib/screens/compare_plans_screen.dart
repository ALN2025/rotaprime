import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/config/plan_limits.dart';
import 'package:rota_prime/widgets/pro_gate.dart';

/// Recursos alinhados ao comportamento real (rota_provider, rota_mapa, entrega ativa).
const _planRows = [
  _CompareRow('Importar planilha XLSX', free: true, pro: true),
  _CompareRow(
    'Entregas por rota (planilha ou manual)',
    free: true,
    pro: true,
    footnote: 'Grátis: até ${PlanLimits.freeMaxDeliveriesPerRoute} · PRO: ilimitado',
  ),
  _CompareRow('Mapa, paradas e entregas (Entregue / Não entregue)', free: true, pro: true),
  _CompareRow('Ordem igual à planilha', free: true, pro: true),
  _CompareRow('Parada manual e histórico', free: true, pro: true),
  _CompareRow('Adicionar parada por CEP + número (ViaCEP)', free: false, pro: true),
  _CompareRow('Criar rota só manual (sem romaneio XLSX)', free: true, pro: true),
  _CompareRow('Traçado laranja no mapa (rota ou trecho pelas ruas)', free: false, pro: true),
  _CompareRow('Otimização de rota (OSRM — menor caminho)', free: false, pro: true),
  _CompareRow('Tempo e distância estimados (OSRM)', free: false, pro: true),
  _CompareRow('Refinar / reotimizar após mudanças', free: false, pro: true),
  _CompareRow('Iniciar otimização no GPS atual', free: false, pro: true),
  _CompareRow(
    'Controle de gastos (KM, valor da rota, despesas, lucro real)',
    free: false,
    pro: true,
  ),
  _CompareRow('Mapa: paradas (pins) e posição GPS — sem linha laranja', free: true, pro: false),
  _CompareRow(
    'Trial ${PlanLimits.proTrialDays} dias PRO (primeira instalação)',
    free: true,
    pro: true,
    footnote:
        'Uma vez por aparelho. Desinstalar/reinstalar → Grátis (sem novo trial).',
  ),
];

class ComparePlansScreen extends ConsumerWidget {
  const ComparePlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final isPro = sub.isPro;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Comparar planos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Neste aparelho: ${PlanLimits.proTrialDays} dias de PRO grátis (trial) na primeira instalação. '
            'Se desinstalar o app e instalar de novo, o trial não reinicia — fica Grátis até ativar PRO com a chave. '
            'Depois do trial: Grátis (até ${PlanLimits.freeMaxDeliveriesPerRoute} entregas/rota). '
            'PRO licenciado: otimização OSRM, traçado laranja, km/tempo e extras.',
            style: const TextStyle(color: Colors.white70, height: 1.45, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _ComparisonTable(rows: _planRows, currentIsPro: isPro),
          const SizedBox(height: 24),
          if (!sub.isLicensedPro)
            ElevatedButton(
              onPressed: () => showProActivationDialog(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                sub.isTrialActive ? 'Comprar PRO (licença permanente)' : 'Ativar PRO com licença',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else
            const Center(
              child: Text(
                'Plano PRO licenciado neste aparelho',
                style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          if (sub.isTrialActive) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Trial PRO: faltam ${sub.trialDaysRemaining} dia${sub.trialDaysRemaining == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFF5EEAD4),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompareRow {
  const _CompareRow(
    this.label, {
    required this.free,
    required this.pro,
    this.footnote,
  });

  final String label;
  final bool free;
  final bool pro;
  final String? footnote;
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.rows, required this.currentIsPro});

  final List<_CompareRow> rows;
  final bool currentIsPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 5, child: SizedBox.shrink()),
                Expanded(
                  flex: 2,
                  child: _ColumnPlanTitle(
                    title: 'Grátis',
                    subtitle: 'R\$ 0',
                    highlight: !currentIsPro,
                    accent: Colors.white,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _ColumnPlanTitle(
                    title: 'PRO',
                    subtitle: 'Licença ROTA PRIME',
                    highlight: currentIsPro,
                    accent: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text(
                    'Recurso',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox.shrink()),
                const Expanded(flex: 2, child: SizedBox.shrink()),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
          for (var i = 0; i < rows.length; i++) ...[
            _ComparisonRowTile(row: rows[i]),
            if (i < rows.length - 1) const Divider(height: 1, color: Color(0xFF2A2A2A)),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRowTile extends StatelessWidget {
  const _ComparisonRowTile({required this.row});

  final _CompareRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: Text(row.label, style: const TextStyle(color: Colors.white, fontSize: 13))),
              Expanded(flex: 2, child: Center(child: _PlanIcon(included: row.free))),
              Expanded(flex: 2, child: Center(child: _PlanIcon(included: row.pro))),
            ],
          ),
          if (row.footnote != null) ...[
            const SizedBox(height: 6),
            Text(
              row.footnote!,
              style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColumnPlanTitle extends StatelessWidget {
  const _ColumnPlanTitle({
    required this.title,
    required this.subtitle,
    required this.highlight,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final bool highlight;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        if (highlight) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Seu plano',
              style: TextStyle(color: AppColors.orange, fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanIcon extends StatelessWidget {
  const _PlanIcon({required this.included});

  final bool included;

  @override
  Widget build(BuildContext context) {
    return Icon(
      included ? Icons.check_circle : Icons.remove_circle_outline,
      size: 22,
      color: included ? AppColors.successGreen : Colors.white24,
    );
  }
}
