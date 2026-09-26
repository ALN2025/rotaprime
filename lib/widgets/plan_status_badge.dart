import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/screens/compare_plans_screen.dart';

/// Brasão compacto: Grátis · Trial · PRO (canto superior do app).
class PlanStatusBadge extends ConsumerWidget {
  const PlanStatusBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final kind = sub.accessKind;

    final (label, detail, Color accent, IconData icon) = switch (kind) {
      PlanAccessKind.licensedPro => (
          'PRO',
          'Licenciado',
          AppColors.orange,
          Icons.verified_rounded,
        ),
      PlanAccessKind.trialPro => (
          'TRIAL',
          '${sub.trialDaysRemaining}d',
          const Color(0xFF5EEAD4),
          Icons.hourglass_top_rounded,
        ),
      PlanAccessKind.free => (
          'GRÁTIS',
          'Plano',
          Colors.white54,
          Icons.lock_open_rounded,
        ),
    };

    final compactLabel = switch (kind) {
      PlanAccessKind.licensedPro => 'PRO',
      PlanAccessKind.trialPro => 'TRIAL ${sub.trialDaysRemaining}d',
      PlanAccessKind.free => 'GRÁTIS',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ComparePlansScreen()),
          );
        },
        borderRadius: BorderRadius.circular(compact ? 20 : 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 10,
            vertical: compact ? 6 : 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 20 : 10),
            color: AppColors.sheet.withValues(alpha: 0.95),
            border: Border.all(
              color: accent.withValues(alpha: compact ? 0.9 : 0.65),
              width: compact ? 1.6 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: compact
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      compactLabel,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        height: 1.1,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          detail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
