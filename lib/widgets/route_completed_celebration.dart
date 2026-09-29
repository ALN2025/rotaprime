import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

/// Efeito “Rota concluída” (estilo Spok).
Future<void> showRouteCompletedCelebration(
  BuildContext context, {
  required int stopCount,
  required int packageCount,
  VoidCallback? onCopyStops,
  Future<void> Function()? onFinishNow,
  Future<void> Function()? onFinanceOptional,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Rota concluída',
    barrierColor: Colors.black.withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (ctx, a1, a2) {
      return _RouteCompletedCelebrationBody(
        stopCount: stopCount,
        packageCount: packageCount,
        onCopyStops: onCopyStops,
        onFinishNow: onFinishNow,
        onFinanceOptional: onFinanceOptional,
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final t = Curves.easeOutCubic.transform(anim.value);
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
      );
    },
  );
}

class _RouteCompletedCelebrationBody extends StatefulWidget {
  const _RouteCompletedCelebrationBody({
    required this.stopCount,
    required this.packageCount,
    this.onCopyStops,
    this.onFinishNow,
    this.onFinanceOptional,
  });

  final int stopCount;
  final int packageCount;
  final VoidCallback? onCopyStops;
  final Future<void> Function()? onFinishNow;
  final Future<void> Function()? onFinanceOptional;

  @override
  State<_RouteCompletedCelebrationBody> createState() =>
      _RouteCompletedCelebrationBodyState();
}

class _RouteCompletedCelebrationBodyState extends State<_RouteCompletedCelebrationBody>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _confetti;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.stopCount;
    final pkg = widget.packageCount;
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _confetti,
            builder: (context, _) {
              return CustomPaint(
                painter: _ConfettiPainter(progress: _confetti.value, seed: stops + pkg),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        final s = 1.0 + _pulse.value * 0.08;
                        return Transform.scale(
                          scale: s,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.successGreen.withValues(alpha: 0.22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.successGreen.withValues(alpha: 0.45),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 56,
                              color: AppColors.successGreen,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Rota concluída!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$stops parada${stops == 1 ? '' : 's'}'
                      '${pkg != stops ? ' · $pkg pacotes' : ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (widget.onCopyStops != null) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          widget.onCopyStops!();
                        },
                        icon: const Icon(Icons.copy_all_outlined),
                        label: const Text('Copiar paradas para uma nova rota'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (widget.onFinishNow != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await widget.onFinishNow!();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Marcar rota como finalizada',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    if (widget.onFinanceOptional != null) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () async {
                          await widget.onFinanceOptional!();
                        },
                        child: const Text(
                          'Informar km e gastos (opcional)',
                          style: TextStyle(color: AppColors.orange, fontSize: 15),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.seed});

  final double progress;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    const n = 36;
    for (var i = 0; i < n; i++) {
      final x0 = rnd.nextDouble() * size.width;
      final delay = rnd.nextDouble() * 0.35;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final y = -20 + t * (size.height + 40);
      final x = x0 + math.sin(t * math.pi * 4 + i) * 18;
      final colors = [
        AppColors.orange,
        AppColors.successGreen,
        Colors.white,
        const Color(0xFF64B5F6),
      ];
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 7, height: 11),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
