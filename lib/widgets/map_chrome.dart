import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

/// Botão circular com vidro — cabeçalho do mapa.
class MapGlassIconButton extends StatelessWidget {
  const MapGlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.black.withValues(alpha: 0.45),
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

/// Faixa inferior fixa (ações) — cantos superiores arredondados e sombra.
class MapBottomDock extends StatelessWidget {
  const MapBottomDock({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 12),
    this.flatTop = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool flatTop;

  @override
  Widget build(BuildContext context) {
    final radius = flatTop
        ? const BorderRadius.vertical(bottom: Radius.circular(20))
        : const BorderRadius.vertical(top: Radius.circular(20));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sheet,
        borderRadius: radius,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: flatTop ? 0.04 : 0.08)),
        ),
        boxShadow: flatTop
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SafeArea(
          top: false,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Gradiente no topo do mapa para legibilidade do cabeçalho.
class MapTopScrim extends StatelessWidget {
  const MapTopScrim({super.key, this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.72),
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão de estatística com vidro.
class MapGlassStatCard extends StatelessWidget {
  const MapGlassStatCard({
    super.key,
    required this.child,
    this.accent,
    this.compact = false,
  });

  final Widget child;
  final Color? accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 12 : 16);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(compact ? 8 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.58),
                Colors.black.withValues(alpha: 0.38),
              ],
            ),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              if (accent != null)
                BoxShadow(
                  color: accent!.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: accent == null
              ? child
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            accent!.withValues(alpha: 0.9),
                            accent!.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                    child,
                  ],
                ),
        ),
      ),
    );
  }
}
