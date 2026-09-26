import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/utils/column_matcher.dart';
import 'package:rota_prime/utils/spx_regex.dart';

String? pickExactRomaneioCell(Map<String, String> cells, List<String> aliases) {
  final normalized = <String, String>{
    for (final e in cells.entries) normalizeHeader(e.key): e.value,
  };
  for (final alias in aliases) {
    final v = normalized[normalizeHeader(alias)];
    if (v != null && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

/// Colunas de ordem explícita na planilha (≠ ID de rastreio de 9 dígitos).

const explicitSequenceColumnAliases = [

  'Sequence',

  'Seq',

  'Ordem',

  'Order',

  'Número ordem',

  'Numero ordem',

  'Nº ordem',

  'Pacote',

  'Package',

  'Package Number',

  'Número do pacote',

  'Numero do pacote',

];



/// Um código por linha no app — sem NF/série + pedido juntos.

const _packageDisplayAliases = [

  'Nº Entrega',

  'No Entrega',

  'Número da Entrega',

  'Numero da Entrega',

  'ID da Entrega',

  'ID Entrega',

  'ID do Pacote',

  'Package ID',

  'SPX TN',

  'SPX',

  'Tracking',

  'TN',

  'Código de Barras',

  'Codigo de Barras',

];



/// Ordem interna / sort: coluna Sequence ou ordem da linha no romaneio.

int importRomaneioSequence(Map<String, String> cells, int displayOrder) {

  final fromSheet = int.tryParse(pickExactRomaneioCell(cells, explicitSequenceColumnAliases) ?? '') ?? 0;

  if (fromSheet > 0) return fromSheet;

  return displayOrder;

}



const _magalogTrackingAliases = [
  'Nº Entrega',
  'No Entrega',
  'Número da Entrega',
  'Numero da Entrega',
  'Entrega',
];

const _loggiTrackingAliases = [
  'ID da Entrega',
  'ID Entrega',
  'Id da Entrega',
  'ID do Pacote',
  'ID Pacote',
  'Package ID',
  'Delivery ID',
];

/// Código único que o entregador vê (Magalog → Nº entrega; Loggi → ID entrega; etc.).
String importRomaneioTracking(
  Map<String, String> cells, {
  RomaneioCarrier carrier = RomaneioCarrier.generico,
}) {
  List<String> prefer;
  switch (carrier) {
    case RomaneioCarrier.magalog:
      prefer = [..._magalogTrackingAliases, ..._packageDisplayAliases];
      break;
    case RomaneioCarrier.loggi:
    case RomaneioCarrier.icsDelivery:
      prefer = [..._loggiTrackingAliases, ..._packageDisplayAliases];
      break;
    default:
      prefer = _packageDisplayAliases;
  }
  final raw = pickCell(cells, prefer)?.trim() ?? '';
  if (raw.isEmpty) return '';
  return extractTrackingCode(raw) ?? raw;
}



/// Texto curto no pin do mapa (legado; mapa usa ordem 1…N).

String compactPinReference({required int sequence, required String tracking}) {

  final tn = tracking.trim();

  if (tn.isNotEmpty) {

    final d = tn.replaceAll(RegExp(r'\D'), '');

    if (d.length >= 4) return d.substring(d.length - 5);

    if (tn.length <= 6) return tn;

    return tn.substring(tn.length - 5);

  }

  if (sequence > 0) {

    final s = '$sequence';

    return s.length <= 5 ? s : s.substring(s.length - 5);

  }

  return '';

}


