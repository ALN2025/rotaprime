import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';
import 'package:rota_prime/utils/parada_packages.dart';

/// Rótulos estilo Circuit: ordem da rota (1/90) ≠ parada logística (Stop) ≠ seq. pacote.

class ParadaLabels {

  ParadaLabels._();



  /// Pacote sem número de ordem no romaneio (ex.: incluído manualmente no app).

  static const latePackageMarker = '++';



  static bool hasShopeeSequence(Parada p) => p.sequence > 0;



  /// Manual/QR sem ordem no romaneio — não confundir com PDF/planilha importada.
  static bool isLateAddedPackage(Parada p) =>
      !hasShopeeSequence(p) && p.spxTn.trim().isEmpty;



  /// Ordenação (romaneio); pacotes sem sequence ficam por último.

  static int packageOrder(Parada p) {

    if (p.sequence > 0) return p.sequence;

    return 900000 + p.ordemExibicao;

  }



  /// Código real do romaneio (Shopee, PDF, ML…) — listas e painel da entrega.
  static String romaneioPackageRef(Parada p) {
    if (isLateAddedPackage(p)) return latePackageMarker;
    final tn = p.spxTn.trim();
    if (tn.isNotEmpty) return tn;
    if (p.sequence > 0) return '${p.sequence}';
    if (p.ordemExibicao > 0) return '${p.ordemExibicao}';
    return latePackageMarker;
  }

  /// Chip sacola: Shopee = ordem do pacote; Magalog/Loggi/mista = pin da rota (1…N).
  static String packageOrderDisplay(Parada p, {List<Parada>? route}) {
    if (isLateAddedPackage(p)) return latePackageMarker;
    if (route != null && routeUsesUnifiedPinOrder(route)) {
      return mapPinLabel(route, p);
    }
    if (p.romaneioCarrier == RomaneioCarrier.shopee && p.sequence > 0) {
      return '${p.sequence}';
    }
    if (p.romaneioLayout == ImportRomaneioLayout.shopeeOrdemPacote && p.sequence > 0) {
      return '${p.sequence}';
    }
    return romaneioPackageRef(p);
  }



  static List<Parada> _rowsAtSameStop(List<Parada> all, Parada p) {
    final key = deliveryAddressKey(p);
    return all.where((x) => deliveryAddressKey(x) == key).toList();
  }

  static List<String> pendingPackageOrderLabelsAtStop(List<Parada> all, Parada p) {
    final rows = _rowsAtSameStop(all, p)
        .where((x) => !x.entregue && !x.falha)
        .toList();
    if (rows.isEmpty) return const [];
    rows.sort((a, b) => packageOrder(a).compareTo(packageOrder(b)));
    return rows.map(packageOrderDisplay).toList();
  }



  /// Pacotes no mesmo endereço (Stop): várias linhas no romaneio.

  static int packageCountAtStop(List<Parada> all, Parada p) {
    return packageUnitsAtAddress(all, p);
  }



  static List<int> packageOrdersAtStop(List<Parada> all, Parada p) {

    return packageOrderLabelsAtStop(all, p)

        .where((label) => label != latePackageMarker)

        .map(int.tryParse)

        .whereType<int>()

        .toList();

  }



  static List<String> packageOrderLabelsAtStop(List<Parada> all, Parada p) {

    final rows = _rowsAtSameStop(all, p);

    if (rows.length <= 1) {

      return [packageOrderDisplay(p, route: all)];

    }

    rows.sort((a, b) => packageOrder(a).compareTo(packageOrder(b)));

    return rows.map((r) => packageOrderDisplay(r, route: all)).toList();

  }



  /// Várias transportadoras na mesma rota (Magalog + Loggi + Shopee…) → pin 1…N unificado.
  static bool routeUsesUnifiedPinOrder(List<Parada> all) {
    if (all.isEmpty) return false;
    final carriers = all.map((p) => p.romaneioCarrier).toSet();
    if (carriers.length > 1) return true;
    final only = carriers.single;
    return only != RomaneioCarrier.shopee &&
        only != RomaneioCarrier.generico;
  }

  /// Texto no círculo do pin — vários pacotes no mesmo AP/endereço = quantidade.
  static String mapPinDisplayLabel(List<Parada> all, Parada p) {
    final count = packageCountAtStop(all, p);
    if (count > 1) return '$count';
    return mapPinLabel(all, p);
  }

  /// Pacotes pendentes no pin (ordens) — painel ao tocar.
  static String mapPinPackageOrdersLine(List<Parada> all, Parada p) {
    final labels = pendingPackageOrderLabelsAtStop(all, p);
    if (labels.isEmpty) {
      return packageOrderLabelsAtStop(all, p).join(', ');
    }
    return labels.join(', ');
  }

  /// Pin no mapa: Shopee pura = ordem do pacote; mista / privadas = ordem na rota (1…N).
  static String mapPinLabel(List<Parada> all, Parada p) {
    if (isLateAddedPackage(p)) return latePackageMarker;
    if (routeUsesUnifiedPinOrder(all) && p.ordemExibicao > 0) {
      return '${p.ordemExibicao}';
    }
    if (p.romaneioCarrier == RomaneioCarrier.shopee && p.sequence > 0) {
      return '${p.sequence}';
    }
    if (p.romaneioLayout == ImportRomaneioLayout.shopeeOrdemPacote && p.sequence > 0) {
      return '${p.sequence}';
    }
    if (p.ordemExibicao > 0) return '${p.ordemExibicao}';
    final idx = all.indexWhere((x) => x.id == p.id && p.id > 0);
    if (idx >= 0) return '${idx + 1}';
    return '${all.indexOf(p) + 1}';
  }



  @Deprecated('Use mapPinLabel')

  static int mapPin(List<Parada> all, Parada p) {

    final label = mapPinLabel(all, p);

    if (label == latePackageMarker) return 0;

    return int.tryParse(label) ?? p.ordemExibicao;

  }



  static String? latePackageHint(Parada p) {

    if (!isLateAddedPackage(p)) return null;

    return 'Sem ordem no romaneio — incluído manualmente no app (++)';

  }



  /// Progresso na rota (ex.: 2/90) — posição na lista, nunca 0/N.
  static String routeProgress(List<Parada> all, Parada p, {int? totalPackages}) {
    final denom = (totalPackages != null && totalPackages > 0)
        ? totalPackages
        : all.length;
    if (denom <= 0) return '0/0';
    var pos = p.ordemExibicao;
    if (pos < 1 || pos > denom) {
      final idx = all.indexWhere((x) => x.id == p.id && p.id > 0);
      final idx2 = idx >= 0 ? idx : all.indexOf(p);
      pos = idx2 >= 0 ? idx2 + 1 : 1;
    }
    return '$pos/$denom';
  }



  static String packageSeqLabel(Parada p) {

    if (p.sequence > 0) return '${p.sequence}';

    return latePackageMarker;

  }



  static String stopLabel(Parada p) {

    if (p.stop > 0) return '${p.stop}';

    return '—';

  }



  static String seqAndStopCompact(Parada p) {

    if (isLateAddedPackage(p)) return latePackageMarker;

    final seq = p.sequence > 0 ? p.sequence : null;

    final stop = p.stop > 0 ? p.stop : null;

    if (seq != null && stop != null && seq != stop) {

      return '$seq • $stop';

    }

    if (stop != null) return stop.toString();

    if (seq != null) return seq.toString();

    return '${p.ordemExibicao}';

  }

  /// Referência clara para listas e pin selecionado (pacote / parada Shopee / ordem na rota).
  static String deliveryReferenceLine(Parada p) {
    final chip = packageOrderDisplay(p);
    final parts = <String>[
      if (chip != latePackageMarker) chip else 'Pacote $chip',
    ];
    if (p.stop > 0) {
      parts.add('Parada ${p.stop}');
    }
    parts.add('Rota ${p.ordemExibicao}');
    return parts.join(' · ');
  }



  static String idLine(Parada p, StopIdDisplay mode) {

    final routeId = 'A${p.ordemExibicao}';

    switch (mode) {

      case StopIdDisplay.modernByRoute:

        final stopPart = p.stop > 0 ? ' • Stop ${p.stop}' : '';

        final ordem = packageOrderDisplay(p);

        final seqPart = isLateAddedPackage(p)

            ? ' • Ordem $ordem (extra)'

            : (p.sequence > 0 && p.sequence != p.stop ? ' • Ordem $ordem' : '');

        return 'ID $routeId$stopPart$seqPart';

      case StopIdDisplay.numericOnly:

        return 'Parada ${packageOrderDisplay(p)}';

    }

  }



  static String mapCalloutTitle(List<Parada> all, Parada p) {

    final labels = packageOrderLabelsAtStop(all, p);

    final stopPart = p.stop > 0 ? 'Parada ${p.stop}' : 'Entrega ${p.ordemExibicao}';

    if (labels.length <= 1) {

      return '$stopPart · Ordem ${labels.first}';

    }

    return '$stopPart · Pacotes ${labels.join(', ')}';

  }



  static String packageQtyLine(List<Parada> all, Parada p) {
    final labels = packageOrderLabelsAtStop(all, p);
    final stopPart = p.stop > 0 ? 'Parada ${p.stop}' : 'Entrega ${p.ordemExibicao}';
    if (labels.length <= 1) {
      return '$stopPart · pacote ${labels.first}';
    }
    return '$stopPart · ${labels.length} pacotes (${labels.join(', ')})';
  }



  static String? packageQuantityDescription(List<Parada> all, Parada p) {

    final count = packageCountAtStop(all, p);

    final labels = packageOrderLabelsAtStop(all, p);

    if (count <= 1 && labels.length <= 1 && !isLateAddedPackage(p)) return null;

    if (isLateAddedPackage(p)) {

      return latePackageHint(p);

    }

    if (labels.length > 1) {

      return 'Quantidade: $count pacotes · ordens ${labels.join(', ')}';

    }

    return 'Quantidade: $count pacotes nesta parada';

  }



  static bool hasMultiplePackagesAtStop(List<Parada> all, Parada p) {

    return packageCountAtStop(all, p) > 1 || packageOrderLabelsAtStop(all, p).length > 1;

  }



  static String sameStopNextPackageNotice(
    List<Parada> all,
    Parada nextPackage,
  ) {
    final pendingLabels = pendingPackageOrderLabelsAtStop(all, nextPackage);
    final pending = pendingLabels.length;
    if (pending <= 0) return '';

    final ordem = packageOrderDisplay(nextPackage);
    final stopPart =
        nextPackage.stop > 0 ? 'parada ${nextPackage.stop}' : 'este endereço';

    if (pending > 1) {
      return 'Mesma $stopPart — faltam $pending pacotes: ${pendingLabels.join(', ')}';
    }

    return 'Mesma $stopPart — falta o pacote ordem $ordem';
  }



  static String routeAndStopLine(List<Parada> all, Parada p, {int? totalPackages}) {
    final stop = p.stop > 0 ? 'Parada ${p.stop}' : 'Stop —';
    return '${routeProgress(all, p, totalPackages: totalPackages)} · $stop';
  }

  /// Subtítulo da lista (sem repetir “Parada N” duas vezes).
  static String deliveryListSubtitle(
    List<Parada> all,
    Parada p, {
    required int totalPackages,
  }) {
    final progress = routeProgress(all, p, totalPackages: totalPackages);
    return '$progress · ${packageQtyCompact(all, p)}';
  }

  static String packageQtyCompact(List<Parada> all, Parada p) {
    if (routeUsesUnifiedPinOrder(all)) {
      final pin = mapPinLabel(all, p);
      final ref = romaneioPackageRef(p);
      final parts = <String>['Pin $pin'];
      if (ref.isNotEmpty && ref != pin && ref != latePackageMarker) {
        parts.add('ID $ref');
      }
      final prazo = p.prazoEntrega.trim();
      if (prazo.isNotEmpty) parts.add('Prazo $prazo');
      return parts.join(' · ');
    }
    final labels = packageOrderLabelsAtStop(all, p);
    final count = packageCountAtStop(all, p);
    final stopPart = p.stop > 0 ? 'Parada ${p.stop}' : 'Rota ${p.ordemExibicao}';
    if (count <= 1 && labels.length <= 1) {
      return '$stopPart · ordem ${labels.first}';
    }
    final orders = labels.join(', ');
    if (count > labels.length) {
      return '$stopPart · $count pacotes ($orders)';
    }
    return '$stopPart · ${labels.length} pacotes ($orders)';
  }

}


