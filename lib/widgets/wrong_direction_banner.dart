import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
/// Aviso estilo Waze: sentido contrário em relação ao alvo.
/// Deve ficar **abaixo** dos cards no topo (coluna do [DriverRouteTopBar]).
class WrongDirectionBanner extends StatefulWidget {
  const WrongDirectionBanner({super.key});

  @override
  State<WrongDirectionBanner> createState() => _WrongDirectionBannerState();
}

class _WrongDirectionBannerState extends State<WrongDirectionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.35 + _pulse.value * 0.25;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.stopFailed.withValues(alpha: glow),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: const Color(0xFFC62828),
        elevation: 8,
        shadowColor: AppColors.stopFailed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95), width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.stopFailed, width: 3),
                  ),
                  child: const Icon(
                    Icons.u_turn_left_rounded,
                    color: Color(0xFFB71C1C),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SENTIDO CONTRÁRIO',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.98),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Vire ou faça retorno — você está indo na direção oposta ao destino.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
