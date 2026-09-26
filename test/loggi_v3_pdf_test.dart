import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/services/import_service.dart';
import 'package:rota_prime/services/pdf_romaneio_parser.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:rota_prime/services/pdf_text_extractor.dart';
import 'package:rota_prime/services/romaneio_parser_service.dart';
import 'package:rota_prime/utils/import_row_filters.dart';

const _path = r'c:\Users\User\Downloads\Telegram Desktop\relatorio_pacotes_v3.pdf';

void main() {
  test('Loggi relatorio_pacotes_v3 — contagem real 45', () async {
    final f = File(_path);
    if (!await f.exists()) {
      // ignore: avoid_print
      print('skip: PDF não encontrado em $_path');
      return;
    }
    final bytes = await f.readAsBytes();
    final name = f.uri.pathSegments.last;
    final text = await extractPdfPlainText(bytes, sourceName: name);
    final doc = await PdfDocument.openData(bytes, sourceName: name);
    // ignore: avoid_print
    print('pages=${doc.pages.length} textLen=${text.length}');
    for (var i = 0; i < doc.pages.length; i++) {
      final raw = await doc.pages[i].loadText();
      final pt = raw?.fullText ?? '';
      final n = RegExp(r'\b56[0-9]{7}\b').allMatches(pt).length;
      // ignore: avoid_print
      print(' page ${i + 1}: len=${pt.length} ids56=$n');
    }
    await doc.dispose();

    final id565 = RegExp(r'\b56[0-9]{7}\b').allMatches(text).length;
    // ignore: avoid_print
    print('56xxxxxxx tokens in text=$id565');

    final lower = text.toLowerCase();
    // ignore: avoid_print
    print(
      'isLoggi=${lower.contains('controle de pacotes')} '
      'isEntregas=${lower.contains('controle de entregas')}',
    );

    final oldAnchor = RegExp(r'(?<![\d/])(\d{9,11})\s+(\d{2}/\d{2}/\d{4})(?!\d)');
    // ignore: avoid_print
    print('old RJ anchor count=${oldAnchor.allMatches(text).length}');

    final pdfParser = PdfRomaneioParser();
    final rows = pdfParser.parse(text);
    // ignore: avoid_print
    print('pdfParser rows=${rows.length}');

    final anchor = RegExp(
      r'(?<![\d/])(\d{9})\s+(\d{2}/\d{2}/\d{4}(?:\s+\d{2}:\d{2})?)(?!\d)',
    );
    final all = anchor.allMatches(text).toList();
    // ignore: avoid_print
    print('raw anchors=${all.length}');
    for (final m in all) {
      // ignore: avoid_print
      print('  id=${m.group(1)} prazo=${m.group(2)}');
    }

    final parsed = await RomaneioParserService().parseRows(bytes, fileName: name);
    // ignore: avoid_print
    print('parseRows=${parsed.length}');

    final r = await ImportService().buildParadas(
      rotaId: 1,
      bytes: bytes,
      fileName: name,
      geocode: false,
    );
    // ignore: avoid_print
    print('buildParadas=${r.paradas.length}');

    final expectedIds = RegExp(
      r'(?:^|\s)(56[4-6][0-9]{5,7})\s+(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2})',
    ).allMatches(text).length;
    expect(
      r.paradas.length,
      expectedIds,
      reason: 'Contagem = IDs Loggi únicos no texto do PDF (sem fantasma de barcode)',
    );
    expect(rows.length, r.paradas.length);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
