import 'package:flutter/material.dart';

/// Assinatura do desenvolvedor com brilho animado (estilo ALN).
class DevSignatureBadge extends StatefulWidget {
  const DevSignatureBadge({
    super.key,
    this.compact = false,
    this.splashFooter = false,
  });

  final bool compact;
  /// Rodapé da splash: só DEV ALN, sem subtítulo longo.
  final bool splashFooter;

  @override
  State<DevSignatureBadge> createState() => _DevSignatureBadgeState();
}

class _DevSignatureBadgeState extends State<DevSignatureBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final compact = widget.compact;
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 16,
            vertical: compact ? 0 : 12,
          ),
          padding: EdgeInsets.symmetric(
            vertical: compact ? 10 : 14,
            horizontal: compact ? 16 : 20,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF9B6BFF),
                const Color(0xFFE879F9),
                (t * 2 % 1),
              )!
                  .withValues(alpha: 0.55),
            ),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + t * 2, 0),
              end: Alignment(1.0 + t * 2, 0),
              colors: const [
                Color(0xFF4A1942),
                Color(0xFF6B2D5C),
                Color(0xFF3D1F54),
                Color(0xFF5A2870),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB565FF).withValues(alpha: 0.25 + 0.15 * (t > 0.5 ? 1 - t : t) * 2),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment(-1 + t * 2, 0),
                    end: Alignment(1 + t * 2, 0),
                    colors: const [
                      Colors.white54,
                      Colors.white,
                      Color(0xFFE9D5FF),
                      Colors.white,
                      Colors.white54,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(
                  'DEV ALN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!widget.splashFooter) ...[
                SizedBox(height: compact ? 2 : 4),
                Text(
                  'Desenvolvedor deste APK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
