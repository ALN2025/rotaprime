import 'package:rota_prime/models/parada.dart';

import 'package:rota_prime/utils/delivery_address_key.dart';

import 'package:rota_prime/utils/parada_packages.dart';



/// Totais da rota: **parada** (endereço) ≠ **pacote** (quantidade real do romaneio).

class RouteDeliveryStats {

  RouteDeliveryStats._();



  static String stopKey(Parada p) => deliveryAddressKey(p);



  static List<Parada> rowsAtSameStop(List<Parada> all, Parada p) {

    final key = deliveryAddressKey(p);

    return all.where((x) => deliveryAddressKey(x) == key).toList();

  }



  static int totalStops(List<Parada> paradas) {

    if (paradas.isEmpty) return 0;

    return paradas.map(stopKey).toSet().length;

  }



  /// Soma [quantidadePacotes] de cada linha (1 por linha se a planilha não tiver coluna Qty).

  static int totalPackages(List<Parada> paradas) => sumPackageUnits(paradas);



  static bool isStopComplete(List<Parada> all, Parada p) {

    final rows = rowsAtSameStop(all, p);

    if (rows.isEmpty) return false;

    return rows.every((x) => x.entregue || x.falha);

  }



  static int completedStops(List<Parada> paradas) {

    final seen = <String>{};

    var n = 0;

    for (final p in paradas) {

      final key = stopKey(p);

      if (!seen.add(key)) continue;

      if (isStopComplete(paradas, p)) n++;

    }

    return n;

  }



  static int deliveredPackages(List<Parada> paradas) {

    var n = 0;

    for (final p in paradas) {

      if (p.entregue) n += packageUnitsOnRow(p);

    }

    return n;

  }



  static int finishedPackages(List<Parada> paradas) {

    var n = 0;

    for (final p in paradas) {

      if (p.entregue || p.falha) n += packageUnitsOnRow(p);

    }

    return n;

  }

  static bool hasPendingDeliveries(List<Parada> paradas) =>
      paradas.any((p) => !p.entregue && !p.falha);

  /// Todas as linhas marcadas (entregue ou não entregue).
  static bool allDeliveriesFinished(List<Parada> paradas) =>
      paradas.isNotEmpty && !hasPendingDeliveries(paradas);



  static int packageDenominator(List<Parada> paradas, {int? importedTotal}) {
    final live = sumPackageUnits(paradas);
    if (paradas.isEmpty) {
      if (importedTotal != null && importedTotal > 0) return importedTotal;
      return live;
    }
    // Romaneio PDF/planilha: 1 linha = 1 pacote — card igual à mensagem da importação.
    if (importedTotal != null && importedTotal > 0) {
      if (paradas.length == importedTotal) return importedTotal;
      if (live > importedTotal && live - importedTotal <= 2) return importedTotal;
    }
    return live;
  }



  static String progressSummary(List<Parada> paradas, {int? importedPackageTotal}) {

    final stops = totalStops(paradas);

    final pkgs = packageDenominator(paradas, importedTotal: importedPackageTotal);

    final stopsDone = completedStops(paradas);

    final pkgsDone = finishedPackages(paradas);

    if (stops <= 0 && pkgs <= 0) return '0 paradas';

    if (pkgs == stops) {

      return '$stopsDone/$stops paradas';

    }

    return '$stopsDone/$stops paradas · $pkgsDone/$pkgs pacotes';

  }



  static String progressFriendly(List<Parada> paradas, {int? importedPackageTotal}) {

    final total = packageDenominator(paradas, importedTotal: importedPackageTotal);

    if (total == 0) return '0 de 0';

    final done = finishedPackages(paradas);

    return '$done de $total';

  }



  static String progressCompact(List<Parada> paradas, {int? importedPackageTotal}) {

    final stops = totalStops(paradas);

    final pkgs = packageDenominator(paradas, importedTotal: importedPackageTotal);

    final stopsDone = completedStops(paradas);

    final pkgsDone = finishedPackages(paradas);

    if (pkgs == stops) return '$stopsDone/$stops';

    return '$stopsDone/$stops · $pkgsDone/$pkgs';

  }

}


