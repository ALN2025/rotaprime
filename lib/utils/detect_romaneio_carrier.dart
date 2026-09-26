import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/services/excel_parser_service.dart';
import 'package:rota_prime/utils/detect_romaneio_layout.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';

/// Identifica transportadora ou layout de PDF/planilha (Shopee, Magalog, Loggi…).
RomaneioCarrier detectRomaneioCarrier(
  List<ParsedRow> rows, {
  required bool isPdf,
  String? fileName,
  String? pdfPlainText,
}) {
  final blob = _haystack(fileName, pdfPlainText, rows);
  if (blob.contains('magalog') ||
      blob.contains('maga log') ||
      blob.contains('protocolo de carregamento')) {
    return RomaneioCarrier.magalog;
  }
  if (blob.contains('loggi')) {
    return RomaneioCarrier.loggi;
  }
  if (blob.contains('ics delivery') || blob.contains('icsdelivery')) {
    return RomaneioCarrier.icsDelivery;
  }

  if (rows.any((r) => (r.cells['Transportadora'] ?? '').toLowerCase() == 'loggi')) {
    return RomaneioCarrier.loggi;
  }

  final layout = detectRomaneioLayout(rows, isPdf: isPdf);
  if (isPdf && layout == ImportRomaneioLayout.pdfProtocoloEntrega) {
    return RomaneioCarrier.magalog;
  }
  if (isPdf &&
      layout == ImportRomaneioLayout.pdfRelatorioRj &&
      rows.any((r) => (r.cells['Prazo'] ?? '').trim().isNotEmpty)) {
    final blob = _haystack(fileName, pdfPlainText, rows);
    if (blob.contains('controle de pacotes')) {
      return RomaneioCarrier.loggi;
    }
  }
  return RomaneioCarrierBranding.fromLayout(layout);
}

String _haystack(String? fileName, String? pdfText, List<ParsedRow> rows) {
  final buf = StringBuffer();
  if (fileName != null) buf.write('${fileName.toLowerCase()} ');
  if (pdfText != null) buf.write('${pdfText.toLowerCase()} ');
  for (final r in rows.take(8)) {
    buf.write('${r.rawLine.toLowerCase()} ');
    for (final e in r.cells.entries) {
      buf.write('${e.key.toLowerCase()} ${e.value.toLowerCase()} ');
    }
  }
  return buf.toString();
}
