import 'dart:typed_data';

import 'package:rota_prime/services/excel_parser_service.dart';
import 'package:rota_prime/services/pdf_romaneio_parser.dart';
import 'package:rota_prime/services/pdf_text_extractor.dart';

/// Planilha (.xlsx/.csv) ou romaneio em PDF.
class RomaneioParserService {
  RomaneioParserService({
    ExcelParserService? excel,
    PdfRomaneioParser? pdfRomaneio,
  })  : _excel = excel ?? ExcelParserService(),
        _pdfRomaneio = pdfRomaneio ?? PdfRomaneioParser();

  final ExcelParserService _excel;
  final PdfRomaneioParser _pdfRomaneio;

  static bool isPdf(Uint8List bytes, {String? fileName}) {
    final n = (fileName ?? '').toLowerCase();
    if (n.endsWith('.pdf')) return true;
    return bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  Future<List<ParsedRow>> parseRows(
    Uint8List bytes, {
    String? fileName,
    void Function(String phaseMessage)? onPhase,
  }) async {
    if (bytes.isEmpty) {
      throw const FormatException('Arquivo vazio');
    }
    if (isPdf(bytes, fileName: fileName)) {
      onPhase?.call('Abrindo PDF e lendo texto do romaneio…');
      final text = await extractPdfPlainText(bytes, sourceName: fileName);
      onPhase?.call('Interpretando entregas do PDF…');
      return _pdfRomaneio.parse(text);
    }
    return _excel.parse(bytes, fileName: fileName);
  }
}
