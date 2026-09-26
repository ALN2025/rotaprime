import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/services/import_service.dart';
import 'package:rota_prime/services/pdf_romaneio_parser.dart';
import 'package:rota_prime/services/pdf_text_extractor.dart';
import 'package:rota_prime/utils/detect_romaneio_carrier.dart';

const _path = r'c:\Users\User\Downloads\Telegram Desktop\ANA INACIO RISCO.pdf';

void main() {
  test('Magalog ANA INACIO RISCO.pdf', () async {
    final f = File(_path);
    if (!await f.exists()) {
      // ignore: avoid_print
      print('skip: $_path');
      return;
    }
    final bytes = await f.readAsBytes();
    final name = f.uri.pathSegments.last;
    final text = await extractPdfPlainText(bytes, sourceName: name);
    // ignore: avoid_print
    print('len=${text.length} head=${text.substring(0, text.length > 300 ? 300 : text.length)}');

    expect(text.toLowerCase(), contains('protocolo de carregamento'));
    expect(
      detectRomaneioCarrier(
        [],
        isPdf: true,
        fileName: name,
        pdfPlainText: text,
      ).toString(),
      contains('magalog'),
    );

    expect(
      () => PdfRomaneioParser().parse(text),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Magalog/Protocolo reconhecido'),
        ),
      ),
      reason: 'PDF scan — só 1 linha de texto; app avisa em vez de rota falsa',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
