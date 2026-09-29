import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';
import 'package:rota_prime/utils/parada_packages.dart';
import 'package:rota_prime/utils/romaneio_package_order.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';
import 'package:rota_prime/utils/scan_payload_parse.dart';

/// Rótulos estilo Circuit: ordem da rota (1/90) ≠ parada logística (Stop) ≠ seq. pacote.

class ParadaLabels {

  ParadaLabels._();



  /// Só entrega incluída no app sem ordem nem código (≠ Shopee `+2` no romaneio).

  static const latePackageMarker = '++';



  static bool hasShopeeSequence(Parada p) =>
      p.sequence > 0 || isShopeePlusPackageOrder(p);



  static bool isShopeePlusPackageOrder(Parada p) =>
      isShopeePlusOrderLabel(p.packageOrderLabel);



  /// Título na lista — não usa só o código BR como “endereço”.
  static String listAddressTitle(Parada p, {String? override}) {
    final o = override?.trim();
    if (o != null && o.isNotEmpty && !isTrackingOnlyText(o)) return o;
    final dest = p.destinationAddress.trim();
    if (dest.isNotEmpty && !isTrackingOnlyText(dest)) return dest;
    final raw = p.rawLine.trim();
    if (raw.isNotEmpty && !isTrackingOnlyText(raw)) return raw;
    final loc = [p.bairro, p.city].where((s) => s.trim().isNotEmpty).join(' · ');
    if (loc.isNotEmpty) return loc;
    return 'Informe nome e endereço da etiqueta';
  }

  /// QR só com BR — falta endereço da etiqueta.
  static bool needsShopeeBagOrder(Parada p) {
    if (!usesShopeeBagOrderOnChip(p)) return false;
    if (p.packageOrderLabel.trim().isNotEmpty) return false;
    return p.sequence <= 0;
  }

  static bool needsAddressFromLabel(Parada p) {
    final dest = p.destinationAddress.trim();
    if (dest.isEmpty) return true;
    if (isTrackingOnlyText(dest)) return true;
    if (dest == p.spxTn.trim() && p.spxTn.trim().isNotEmpty) return true;
    return false;
  }

  /// Linha do código (BR / ID) abaixo do endereço.
  static String? listTrackingLine(Parada p) {
    final spx = p.spxTn.trim();
    if (spx.isEmpty) return null;
    final title = listAddressTitle(p);
    if (title.contains(spx)) return null;
    return spx;
  }

  /// Pin no mapa: ordem na rota (1…N); QR/extra usa o mesmo (não `++` se tem BR).
  static String qrAddedPinLabel(List<Parada> all, Parada p) {
    if (p.ordemExibicao > 0) return '${p.ordemExibicao}';
    return mapPinLabel(all, p);
  }

  /// Manual/QR no app — sem ordem, sem `+N` Shopee, sem tracking.
  static bool isLateAddedPackage(Parada p) {
    if (isShopeePlusPackageOrder(p)) return false;
    if (p.sequence > 0) return false;
    if (p.spxTn.trim().isNotEmpty) return false;
    return true;
  }



  /// Ordenação (romaneio); pacotes sem sequence ficam por último.

  static int packageOrder(Parada p) {

    if (p.sequence > 0) return p.sequence;

    return 900000 + p.ordemExibicao;

  }



  static bool usesShopeeBagOrderOnChip(Parada p) {
    return p.romaneioLayout == ImportRomaneioLayout.shopeeOrdemPacote ||
        p.romaneioCarrier == RomaneioCarrier.shopee;
  }

  /// Código real do romaneio (Shopee, PDF, ML…) — listas e painel da entrega.
  static String romaneioPackageRef(Parada p) {
    if (isLateAddedPackage(p)) return latePackageMarker;
    final plusLabel = p.packageOrderLabel.trim();
    if (plusLabel.isNotEmpty) return plusLabel;
    if (usesShopeeBagOrderOnChip(p)) {
      if (p.sequence > 0) return '${p.sequence}';
      final tn = p.spxTn.trim();
      if (tn.isNotEmpty && !isTrackingOnlyText(tn)) return tn;
      return '—';
    }
    final carrier = RomaneioCarrierBranding.carrierOf(p);
    if (carrier == RomaneioCarrier.magalog ||
        carrier == RomaneioCarrier.loggi ||
        carrier == RomaneioCarrier.rjRelatorioEntregas) {
      final tn = p.spxTn.trim();
      if (tn.isNotEmpty) return tn;
    }
    final tn = p.spxTn.trim();
    if (tn.isNotEmpty) return tn;
    if (p.sequence > 0) return '${p.sequence}';
    if (p.ordemExibicao > 0) return '${p.ordemExibicao}';
    return latePackageMarker;
  }

  /// Chip sacola / ícone pacote: código do romaneio (Shopee, Magalog, Loggi…) — não a ordem da rota.
  static String packageOrderDisplay(Parada p, {List<Parada>? route}) {
    if (isLateAddedPackage(p)) return latePackageMarker;
    return romaneioPackageRef(p);
  }



  static List<Parada> _rowsAtSameStop(List<Parada> all, Parada p) {
    return paradasAtSameBuildingSite(all, p);
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



  /// Sempre pin 1…N na rota (Magalog + Loggi + Shopee na mesma entrega).
  static bool routeUsesUnifiedPinOrder(List<Parada> all) => all.isNotEmpty;

  /// Texto no círculo do pin — vários pacotes no mesmo AP/endereço = quantidade.
  static String mapPinDisplayLabel(List<Parada> all, Parada p) {
    final count = packageCountAtStop(all, p);
    if (count > 1) return '$count';
    return mapPinLabel(all, p);
  }

  /// Rótulos dos pins representativos — uma passada (rotas 100+ paradas).
  static Map<int, String> mapPinDisplayLabelsForRepresentatives(
    List<Parada> all,
    List<Parada> representatives,
  ) {
    final out = <int, String>{};
    for (final p in representatives) {
      final count = packageCountAtStop(all, p);
      if (count > 1) {
        out[p.id] = '$count';
        continue;
      }
      out[p.id] = mapPinLabel(all, p);
    }
    return out;
  }

  /// Pacotes pendentes no pin (ordens) — painel ao tocar.
  static String mapPinPackageOrdersLine(List<Parada> all, Parada p) {
    final labels = pendingPackageOrderLabelsAtStop(all, p);
    if (labels.isEmpty) {
      return packageOrderLabelsAtStop(all, p).join(', ');
    }
    return labels.join(', ');
  }

  /// Pin no mapa = ordem na rota (1…N), todas as transportadoras.
  /// Código do pacote (Shopee, +N, ID Loggi/Magalog) fica no chip e no painel — não no pin.
  /// Vários pacotes no mesmo endereço: quantidade no pin ([mapPinDisplayLabel]).
  static String mapPinLabel(List<Parada> all, Parada p) {
    if (isLateAddedPackage(p)) return latePackageMarker;
    if (p.spxTn.trim().isNotEmpty && p.ordemExibicao > 0) {
      return '${p.ordemExibicao}';
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

    return 'Sem ordem no romaneio — incluído manualmente no app ($latePackageMarker)';

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
      return 'Faltam $pending pacotes aqui (${pendingLabels.join(', ')}). Toque Entregue de novo.';
    }

    return 'Falta 1 pacote aqui (ordem $ordem). Toque Entregue de novo.';
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


