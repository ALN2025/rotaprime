import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/utils/romaneio_package_order.dart';

void main() {
  test('parseRomaneioSheetOrder — +2 Shopee', () {
    final o = parseRomaneioSheetOrder('+2', 10);
    expect(o.sequence, 2);
    expect(o.displayLabel, '+2');
  });

  test('parseRomaneioSheetOrder — + 15 com espaço', () {
    final o = parseRomaneioSheetOrder('+ 15', 1);
    expect(o.displayLabel, '+15');
  });

  test('Shopee +2 no romaneio — pin rota, chip +2, não ++', () {
    final p = Parada()
      ..ordemExibicao = 8
      ..sequence = 2
      ..packageOrderLabel = '+2'
      ..spxTn = 'BR305557690';
    final all = [p];

    expect(ParadaLabels.isLateAddedPackage(p), isFalse);
    expect(ParadaLabels.mapPinLabel(all, p), '8');
    expect(ParadaLabels.packageOrderDisplay(p), '+2');
  });

  test('App manual sem ordem — ++', () {
    final p = Parada()..ordemExibicao = 3;
    expect(ParadaLabels.isLateAddedPackage(p), isTrue);
    expect(ParadaLabels.packageOrderDisplay(p), '++');
  });
}
