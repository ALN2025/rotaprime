import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';

/// Transportadora ao incluir pacote por QR (igual romaneio importado).
class QrCarrierInfer {
  QrCarrierInfer._();

  static RomaneioCarrier fromTrackingCode(String code) {
    final c = code.trim().toUpperCase();
    if (c.startsWith('BR')) return RomaneioCarrier.shopee;
    if (c.startsWith('ML')) return RomaneioCarrier.generico;
    if (c.startsWith('SPX')) return RomaneioCarrier.shopee;
    return RomaneioCarrier.generico;
  }

  static RomaneioCarrier fromRoute(List<Parada> paradas) {
    if (paradas.isEmpty) return RomaneioCarrier.generico;
    final counts = <RomaneioCarrier, int>{};
    for (final p in paradas) {
      final c = RomaneioCarrierBranding.carrierOf(p);
      counts[c] = (counts[c] ?? 0) + 1;
    }
    RomaneioCarrier? best;
    var max = 0;
    counts.forEach((c, n) {
      if (n > max) {
        max = n;
        best = c;
      }
    });
    return best ?? RomaneioCarrier.generico;
  }

  static RomaneioCarrier resolve({
    required String trackingCode,
    required List<Parada> routeParadas,
  }) {
    final dominant = fromRoute(routeParadas);
    if (dominant != RomaneioCarrier.generico) return dominant;
    return fromTrackingCode(trackingCode);
  }

  static ImportRomaneioLayout layoutFor(RomaneioCarrier carrier) {
    return switch (carrier) {
      RomaneioCarrier.shopee => ImportRomaneioLayout.shopeeOrdemPacote,
      RomaneioCarrier.magalog => ImportRomaneioLayout.pdfProtocoloEntrega,
      RomaneioCarrier.loggi => ImportRomaneioLayout.pdfRelatorioRj,
      _ => ImportRomaneioLayout.padrao,
    };
  }
}
