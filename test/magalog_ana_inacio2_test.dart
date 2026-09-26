import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/services/import_service.dart';
import 'package:rota_prime/services/pdf_romaneio_parser.dart';
import 'package:rota_prime/services/pdf_text_extractor.dart';
import 'package:rota_prime/utils/detect_romaneio_carrier.dart';

const _path = r'c:\Users\User\Downloads\ana inacio 2.pdf';

void main() {
  test('Magalog ana inacio 2.pdf — parse e contagem', () async {
    final f = File(_path);
    if (!await f.exists()) {
      // ignore: avoid_print
      print('skip: $_path');
      return;
    }
    final bytes = await f.readAsBytes();
    final name = f.uri.pathSegments.last;
    final text = await extractPdfPlainText(bytes, sourceName: name);
    final doc = await PdfDocument.openData(bytes, sourceName: name);
    // ignore: avoid_print
    print('pages=${doc.pages.length} textLen=${text.length}');
    for (var i = 0; i < doc.pages.length; i++) {
      final t = (await doc.pages[i].loadText())?.fullText ?? '';
      final n = RegExp(r'(?:^|\s)(30[0-9]{7})').allMatches(t.replaceAll('\n', ' ')).length;
      // ignore: avoid_print
      print(' p${i + 1} len=${t.length} anchors30=$n');
    }
    await doc.dispose();

    final rows = PdfRomaneioParser().parse(text);
    final carrier = detectRomaneioCarrier(rows, isPdf: true, fileName: name, pdfPlainText: text);
    final built = await ImportService().buildParadas(
      rotaId: 1,
      bytes: bytes,
      fileName: name,
      geocode: false,
    );

    // ignore: avoid_print
    print('parser=${rows.length} built=${built.paradas.length} carrier=$carrier');
    // ignore: avoid_print
    print('summary=${built.summaryLabel}');
    if (rows.isNotEmpty) {
      // ignore: avoid_print
      print('first=${rows.first.cells['Nº Entrega']} last=${rows.last.cells['Nº Entrega']}');
    }

    expect(text.toLowerCase(), contains('protocolo de carregamento'));
    expect(carrier, RomaneioCarrier.magalog);
    expect(built.paradas.length, rows.length);
    expect(built.paradas.length, greaterThan(2));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
