import 'package:flutter/material.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';

/// Logo da transportadora no painel de info (pequeno, nítido — não no pin do mapa).
class CarrierDeliveryBadge extends StatelessWidget {
  const CarrierDeliveryBadge({
    super.key,
    required this.parada,
    this.compact = false,
  });

  final Parada parada;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final carrier = RomaneioCarrierBranding.carrierOf(parada);
    if (!RomaneioCarrierBranding.showsDeliveryBadge(carrier)) {
      return const SizedBox.shrink();
    }

    final asset = RomaneioCarrierBranding.logoAssetPath(carrier);
    final height = compact ? 22.0 : 26.0;
    final maxWidth = compact ? 76.0 : 92.0;
    final label = RomaneioCarrierBranding.displayName(carrier);
    final color = RomaneioCarrierBranding.accent(carrier);

    Widget content;
    if (asset != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height, maxWidth: maxWidth),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _textBadge(label, color, compact),
        ),
      );
    } else {
      content = _textBadge(label, color, compact);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _textBadge(String label, Color color, bool compact) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: compact ? 11 : 12,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
    );
  }
}
