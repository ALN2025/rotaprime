import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/utils/parada_labels.dart';

void main() {
  test('Shopee — pin = ordem na rota; chip = código do pacote', () {
    final p = Parada()
      ..ordemExibicao = 3
      ..sequence = 42
      ..spxTn = 'BR305557690'
      ..romaneioLayout = ImportRomaneioLayout.shopeeOrdemPacote;
    final all = [p];

    expect(ParadaLabels.mapPinLabel(all, p), '3');
    expect(ParadaLabels.packageOrderDisplay(p), 'BR305557690');
  });

  test('PDF Relatório RJ — pin rota; chip = ID Loggi', () {
    final p = Parada()
      ..ordemExibicao = 3
      ..sequence = 3
      ..spxTn = '563608526'
      ..romaneioCarrier = RomaneioCarrier.loggi
      ..romaneioLayout = ImportRomaneioLayout.pdfRelatorioRj;
    final all = [p];

    expect(ParadaLabels.mapPinLabel(all, p), '3');
    expect(ParadaLabels.packageOrderDisplay(p, route: all), '563608526');
  });

  test('PDF Protocolo — pin rota; chip = ID Magalog', () {
    final p = Parada()
      ..ordemExibicao = 5
      ..sequence = 5
      ..spxTn = '305557690'
      ..romaneioCarrier = RomaneioCarrier.magalog
      ..romaneioLayout = ImportRomaneioLayout.pdfProtocoloEntrega;
    final all = [p];

    expect(ParadaLabels.mapPinLabel(all, p), '5');
    expect(ParadaLabels.packageOrderDisplay(p, route: all), '305557690');
  });

  test('Rota mista — pin 1…N; chip por transportadora', () {
    final shopee = Parada()
      ..ordemExibicao = 1
      ..sequence = 99
      ..spxTn = 'BR99'
      ..romaneioCarrier = RomaneioCarrier.shopee
      ..romaneioLayout = ImportRomaneioLayout.shopeeOrdemPacote;
    final magalog = Parada()
      ..ordemExibicao = 2
      ..spxTn = '88776655'
      ..romaneioCarrier = RomaneioCarrier.magalog;
    final all = [shopee, magalog];

    expect(ParadaLabels.routeUsesUnifiedPinOrder(all), isTrue);
    expect(ParadaLabels.mapPinLabel(all, shopee), '1');
    expect(ParadaLabels.mapPinLabel(all, magalog), '2');
    expect(ParadaLabels.packageOrderDisplay(shopee, route: all), 'BR99');
    expect(ParadaLabels.packageOrderDisplay(magalog, route: all), '88776655');
  });
}
