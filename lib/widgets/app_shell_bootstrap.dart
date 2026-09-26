import 'package:flutter/material.dart';
import 'package:rota_prime/widgets/plan_status_badge.dart';

/// Faixa superior do shell: brasão do plano **no fluxo do layout** (não flutuando por cima).
class AppShellPlanBadgeStrip extends StatelessWidget {
  const AppShellPlanBadgeStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.fromLTRB(12, 4, 10, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: PlanStatusBadge(compact: true),
      ),
    );
  }
}

/// Envolve telas do rodapé (Rotas / Entregas / Mais) com o mesmo chrome superior.
class AppShellBootstrap extends StatelessWidget {
  const AppShellBootstrap({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppShellPlanBadgeStrip(),
        Expanded(child: body),
      ],
    );
  }
}

/// Título de aba + brasão na mesma linha (Entregas, Mais, etc.).
class AppShellTitleRow extends StatelessWidget {
  const AppShellTitleRow({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const PlanStatusBadge(compact: true),
        ],
      ),
    );
  }
}
