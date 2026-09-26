import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';

void main() {
  test('Shopee — selo e logo como Magalog/Loggi', () {
    expect(RomaneioCarrierBranding.showsDeliveryBadge(RomaneioCarrier.shopee), isTrue);
    expect(
      RomaneioCarrierBranding.logoAssetPath(RomaneioCarrier.shopee),
      'assets/carriers/shopee.png',
    );
    expect(RomaneioCarrierBranding.displayName(RomaneioCarrier.shopee), 'Shopee');
  });

  test('Parada planilha Shopee — badge nas infos', () {
    final p = Parada()
      ..romaneioCarrier = RomaneioCarrier.shopee
      ..romaneioLayout = ImportRomaneioLayout.shopeeOrdemPacote;
    expect(RomaneioCarrierBranding.showsDeliveryBadgeForParada(p), isTrue);
    expect(RomaneioCarrierBranding.carrierOf(p), RomaneioCarrier.shopee);
  });
}
