import 'package:rota_prime/models/parada.dart';

import 'package:rota_prime/utils/column_matcher.dart';

import 'package:rota_prime/utils/delivery_address_key.dart';



export 'package:rota_prime/utils/stop_route_order.dart';



/// Pacotes na linha (coluna Quantidade/Pacotes ou 1 por linha do romaneio).

int packageUnitsOnRow(Parada p) {

  final n = p.quantidadePacotes;

  return n < 1 ? 1 : n;

}



/// Total real importado: soma das quantidades da planilha (não agrupamento genérico).

int sumPackageUnits(Iterable<Parada> paradas) {

  var total = 0;

  for (final p in paradas) {

    total += packageUnitsOnRow(p);

  }

  return total;

}



int packageUnitsAtAddress(List<Parada> all, Parada p) {
  var total = 0;
  for (final row in all) {
    if (sameDeliveryLocation(row, p)) {
      total += packageUnitsOnRow(row);
    }
  }
  return total < 1 ? 1 : total;
}



/// Mantém [quantidadePacotes] de cada linha como veio da planilha (sem sobrescrever).

void finalizePackageQtyFromImport(List<Parada> paradas) {

  for (final p in paradas) {

    if (p.quantidadePacotes < 1) {

      p.quantidadePacotes = 1;

    }

  }

}



int parsePackageQtyFromCells(Map<String, String> cells) {

  final raw = pickCell(cells, packageQtyAliases);

  final n = int.tryParse(raw ?? '');

  if (n == null || n < 1) return 1;

  return n;

}


