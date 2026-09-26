import 'package:flutter/material.dart';
import 'package:rota_prime/app/app_info.dart';
import 'package:rota_prime/widgets/dev_signature_badge.dart';

/// Intro padrão ALN (mesmo estilo Meu Controle) — ROTA PRIME.
class AlnSplashView extends StatefulWidget {
  const AlnSplashView({super.key});

  @override
  State<AlnSplashView> createState() => _AlnSplashViewState();
}

class _AlnSplashViewState extends State<AlnSplashView>
    with SingleTickerProviderStateMixin {
  static const _peach = Color(0xFFE8A090);
  static const _lavender = Color(0xFFC4B5FD);

  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF050505)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _glowBlob(220, 0.06),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: _glowBlob(260, 0.05),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/LOGO.png',
                    height: 88,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 28),
                  const _AlnSystemMark(peach: _peach),
                  const SizedBox(height: 28),
                  const Text(
                    AppInfo.productName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Suas entregas no mapa — offline,\norganize rotas e romaneio',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'OTIMIZAÇÃO DE ROTAS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.32),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth.clamp(0.0, 280.0);
                          final t = _progress.value;
                          final fill = w * (0.25 + 0.75 * t);
                          return Column(
                            children: [
                              SizedBox(
                                width: w,
                                height: 3,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: fill,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2),
                                          gradient: const LinearGradient(
                                            colors: [_peach, _lavender],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Inicializando •',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.38),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    'v${AppInfo.displayVersion}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.28),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const DevSignatureBadge(compact: true, splashFooter: true),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _peach.withValues(alpha: alpha),
      ),
    );
  }
}

class _AlnSystemMark extends StatelessWidget {
  const _AlnSystemMark({required this.peach});

  final Color peach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'A . L . N',
            style: TextStyle(
              color: peach,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SYSTEM',
            style: TextStyle(
              color: peach.withValues(alpha: 0.92),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 5,
            ),
          ),
        ],
      ),
    );
  }
}
