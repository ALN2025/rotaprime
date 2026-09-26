import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/services/import_service.dart';
import 'package:rota_prime/services/romaneio_parser_service.dart';
import 'package:rota_prime/utils/import_row_filters.dart';

const _files = [
  r'c:\Users\User\Downloads\Telegram Desktop\ana12.1.pdf',
  r'c:\Users\User\Downloads\Telegram Desktop\relatorio_entregas_corrigido (31).pdf',
];

void main() {
  test('buildParadas PDF — diagnóstico', () async {
    final svc = ImportService();
    final parser = RomaneioParserService();
    for (final path in _files) {
      final f = File(path);
      if (!await f.exists()) {
        // ignore: avoid_print
        print('skip missing $path');
        continue;
      }
      final bytes = await f.readAsBytes();
      final name = f.uri.pathSegments.last;
      final parsed = await parser.parseRows(bytes, fileName: name);
      // ignore: avoid_print
      print('$name: parsed=${parsed.length}');
      var skip = 0;
      for (final row in parsed) {
        if (shouldSkipRomaneioRow(row.cells)) skip++;
      }
      // ignore: avoid_print
      print('  skipped=$skip');

      final r = await svc.buildParadas(
        rotaId: 1,
        bytes: bytes,
        fileName: name,
        geocode: false,
      );
      // ignore: avoid_print
      print('  paradas=${r.paradas.length}');
      expect(r.paradas.length, greaterThan(0), reason: path);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
