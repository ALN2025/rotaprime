import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/services/excel_parser_service.dart';
import 'package:rota_prime/utils/column_matcher.dart';
import 'package:rota_prime/utils/import_romaneio_ref.dart';

/// Define pin vs info após parse do arquivo (PDF ou planilha).
ImportRomaneioLayout detectRomaneioLayout(
  List<ParsedRow> rows, {
  required bool isPdf,
}) {
  if (rows.isEmpty) return ImportRomaneioLayout.padrao;

  if (isPdf) {
    final cells = rows.first.cells;
    final hasEntrega = pickExactRomaneioCell(cells, const ['Nº Entrega', 'No Entrega']) != null;
    final hasIdPacote = pickExactRomaneioCell(cells, const ['ID do Pacote', 'Package ID']) != null;
    if (hasIdPacote && !hasEntrega) {
      return ImportRomaneioLayout.pdfRelatorioRj;
    }
    if (hasEntrega) {
      return ImportRomaneioLayout.pdfProtocoloEntrega;
    }
    return ImportRomaneioLayout.padrao;
  }

  if (_looksLikeShopeeManifest(rows)) {
    return ImportRomaneioLayout.shopeeOrdemPacote;
  }
  return ImportRomaneioLayout.padrao;
}

bool _looksLikeShopeeManifest(List<ParsedRow> rows) {
  final sample = rows.length > 30 ? rows.sublist(0, 30) : rows;
  var withSeq = 0;
  var withTracking = 0;
  for (final row in sample) {
    final seqRaw = pickExactRomaneioCell(row.cells, explicitSequenceColumnAliases);
    final n = int.tryParse(seqRaw ?? '');
    if (n != null && n > 0 && n <= 99999) withSeq++;
    final track = pickCell(row.cells, spxAliases)?.trim() ?? '';
    if (track.isNotEmpty) withTracking++;
  }
  if (sample.isEmpty) return false;
  return withSeq >= (sample.length * 0.5).ceil() &&
      withTracking >= (sample.length * 0.35).ceil();
}
