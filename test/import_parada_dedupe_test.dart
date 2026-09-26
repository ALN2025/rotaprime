import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/import_parada_dedupe.dart';

void main() {
  test('remove pacotes duplicados pelo mesmo ID', () {
    final a = Parada()
      ..spxTn = '563608526'
      ..destinationAddress = 'Rua A'
      ..ordemExibicao = 1;
    final b = Parada()
      ..spxTn = '563608526'
      ..destinationAddress = 'Rua A dup'
      ..ordemExibicao = 2;
    final c = Parada()
      ..spxTn = '563513471'
      ..destinationAddress = 'Rua B'
      ..ordemExibicao = 3;

    final out = dedupeImportParadas([a, b, c]);
    expect(out.paradas.length, 2);
    expect(out.duplicatesRemoved, 1);
    expect(out.paradas.first.spxTn, '563608526');
    expect(out.paradas.last.ordemExibicao, 2);
  });

  test('merge rota — não duplica mesmo ID entre romaneios', () {
    final a = Parada()
      ..spxTn = '565481711'
      ..ordemExibicao = 1;
    final b = Parada()
      ..spxTn = '565508572'
      ..ordemExibicao = 2;
    final dup = Parada()
      ..spxTn = '565481711'
      ..ordemExibicao = 1;
    final merged = mergeRouteParadas([a, b], [dup]);
    expect(merged.length, 2);
    expect(merged.map((p) => p.spxTn).toList(), ['565481711', '565508572']);
  });

  test('countNewParadasForMerge — romaneio repetido = zero novos', () {
    final a = Parada()
      ..spxTn = '111'
      ..ordemExibicao = 1;
    final b = Parada()
      ..spxTn = '222'
      ..ordemExibicao = 2;
    final again = Parada()
      ..spxTn = '111'
      ..ordemExibicao = 1;
    expect(countNewParadasForMerge([a, b], [again]), 0);
    expect(countNewParadasForMerge([a, b], [again, Parada()..spxTn = '333']), 1);
  });
}
