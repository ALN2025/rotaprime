import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/widgets/brand_logo.dart';

/// Cabeçalho estilo mockup: faixa preta · menu · logo PNG · cards.
class RouteMapHeaderBar extends StatelessWidget {
  const RouteMapHeaderBar({
    super.key,
    required this.deliveriesDone,
    required this.deliveriesTotal,
    required this.distanceLabel,
    required this.durationLabel,
    this.routeTitle,
    this.onMenu,
  });

  final int deliveriesDone;
  final int deliveriesTotal;
  final String distanceLabel;
  final String durationLabel;
  final String? routeTitle;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final progress = deliveriesTotal > 0 ? deliveriesDone / deliveriesTotal : 0.0;

    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                ),
                const Expanded(
                  child: Center(
                    child: BrandLogo(height: 54),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            if (routeTitle != null && routeTitle!.trim().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  routeTitle!.trim(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _HeaderStatCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entregas',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$deliveriesDone / $deliveriesTotal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Spacer(),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.12),
                                color: AppColors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeaderStatCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _MetricLine(label: 'Distância', value: distanceLabel),
                            const SizedBox(height: 14),
                            _MetricLine(label: 'Tempo estimado', value: durationLabel),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(minHeight: 108),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
