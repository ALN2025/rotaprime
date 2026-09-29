import 'package:flutter/material.dart';
import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';

class RomaneioCarrierBranding {
  RomaneioCarrierBranding._();

  /// PDF Loggi (Relatório + coluna Prazo) — selo igual Magalog/SPX.
  static bool isLikelyLoggiParada(Parada p) {
    if (p.romaneioCarrier == RomaneioCarrier.loggi) return true;
    if (p.romaneioLayout != ImportRomaneioLayout.pdfRelatorioRj) return false;
    if (p.prazoEntrega.trim().isNotEmpty) return true;
    return p.rawLine.toLowerCase().contains('loggi');
  }

  static RomaneioCarrier carrierOf(Parada p) {
    if (isLikelyLoggiParada(p)) return RomaneioCarrier.loggi;
    switch (p.romaneioCarrier) {
      case RomaneioCarrier.protocoloCarregamento:
        return RomaneioCarrier.magalog;
      case RomaneioCarrier.generico:
        if (p.romaneioLayout == ImportRomaneioLayout.pdfProtocoloEntrega) {
          return RomaneioCarrier.magalog;
        }
        return RomaneioCarrier.generico;
      default:
        return p.romaneioCarrier;
    }
  }

  /// Corrige paradas antigas salvas como RJ/genérico apesar de serem Loggi.
  static void normalizeLoggiCarriers(Iterable<Parada> paradas) {
    for (final p in paradas) {
      if (isLikelyLoggiParada(p)) {
        p.romaneioCarrier = RomaneioCarrier.loggi;
      }
    }
  }

  static RomaneioCarrier fromLayout(ImportRomaneioLayout layout) {
    switch (layout) {
      case ImportRomaneioLayout.shopeeOrdemPacote:
        return RomaneioCarrier.shopee;
      case ImportRomaneioLayout.pdfRelatorioRj:
        return RomaneioCarrier.rjRelatorioEntregas;
      case ImportRomaneioLayout.pdfProtocoloEntrega:
        return RomaneioCarrier.magalog;
      case ImportRomaneioLayout.padrao:
        return RomaneioCarrier.generico;
    }
  }

  static String shortBadge(RomaneioCarrier c) => switch (c) {
        RomaneioCarrier.shopee => 'SPX',
        RomaneioCarrier.rjRelatorioEntregas => 'RJ',
        RomaneioCarrier.protocoloCarregamento => 'PRT',
        RomaneioCarrier.magalog => 'MGL',
        RomaneioCarrier.loggi => 'LGG',
        RomaneioCarrier.icsDelivery => 'ICS',
        RomaneioCarrier.generico => '•',
      };

  /// Selo no painel — Shopee, Magalog e Loggi (logo PNG ou texto em assets/carriers/).
  static bool showsDeliveryBadge(RomaneioCarrier c) => switch (c) {
        RomaneioCarrier.shopee ||
        RomaneioCarrier.magalog ||
        RomaneioCarrier.loggi ||
        RomaneioCarrier.protocoloCarregamento =>
          true,
        _ => false,
      };

  static bool showsDeliveryBadgeForParada(Parada p) =>
      showsDeliveryBadge(carrierOf(p));

  /// `assets/carriers/shopee.png`, `magalog.png`, `loggi.png` — null = fallback texto.
  static String? logoAssetPath(RomaneioCarrier c) => switch (c) {
        RomaneioCarrier.shopee => 'assets/carriers/shopee.png',
        RomaneioCarrier.magalog => 'assets/carriers/magalog.png',
        RomaneioCarrier.loggi => 'assets/carriers/loggi.png',
        _ => null,
      };

  static String displayName(RomaneioCarrier c) => switch (c) {
        RomaneioCarrier.shopee => 'Shopee',
        RomaneioCarrier.rjRelatorioEntregas => 'Romaneio',
        RomaneioCarrier.protocoloCarregamento => 'Romaneio',
        RomaneioCarrier.magalog => 'Magalog',
        RomaneioCarrier.loggi => 'Loggi',
        RomaneioCarrier.icsDelivery => 'ICS Delivery',
        RomaneioCarrier.generico => 'Romaneio',
      };

  /// Rótulo do código no painel / chip do pacote.
  static String deliveryCodeHint(RomaneioCarrier c) => switch (c) {
        RomaneioCarrier.shopee => 'Ordem do pacote',
        RomaneioCarrier.magalog => 'Nº da entrega',
        RomaneioCarrier.loggi => 'ID da entrega',
        RomaneioCarrier.icsDelivery => 'ID da entrega',
        RomaneioCarrier.rjRelatorioEntregas => 'ID do pacote',
        RomaneioCarrier.protocoloCarregamento => 'Nº entrega',
        RomaneioCarrier.generico => 'Código do pacote',
      };

  static Color accent(RomaneioCarrier c) => switch (c) {
        RomaneioCarrier.shopee => const Color(0xFFEE4D2D),
        RomaneioCarrier.magalog => const Color(0xFF1565C0),
        RomaneioCarrier.loggi => const Color(0xFF00AFFF),
        RomaneioCarrier.icsDelivery => const Color(0xFF2E7D32),
        RomaneioCarrier.rjRelatorioEntregas => const Color(0xFF6A1B9A),
        RomaneioCarrier.protocoloCarregamento => const Color(0xFF00838F),
        RomaneioCarrier.generico => const Color(0xFF757575),
      };

  /// Pin no mapa = ordem na rota (1…N) para todas as transportadoras.
  static bool pinUsesRouteOrder(RomaneioCarrier c) => true;
}
