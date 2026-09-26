import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/services/pdf_romaneio_parser.dart';
import 'package:rota_prime/services/pdf_text_extractor.dart';
import 'package:rota_prime/utils/column_matcher.dart';

const _protocoloPath =
    r'c:\Users\User\Downloads\Telegram Desktop\ana12.1.pdf';
const _relatorioPath =
    r'c:\Users\User\Downloads\Telegram Desktop\relatorio_entregas_corrigido (31).pdf';
const _loggiPacotesPath =
    r'c:\Users\User\Downloads\Telegram Desktop\relatorio_pacotes_v3.pdf';
const _magalogAna2Path = r'c:\Users\User\Downloads\ana inacio 2.pdf';

Future<List<dynamic>> _importPdf(String path, String label) async {
  final file = File(path);
  if (!await file.exists()) {
    return [label, 'ARQUIVO_NAO_ENCONTRADO', 0, ''];
  }
  final bytes = await file.readAsBytes();
  final text = await extractPdfPlainText(bytes, sourceName: file.uri.pathSegments.last);
  final rows = PdfRomaneioParser().parse(text);
  final sample = rows.take(3).map((r) {
    final addr = pickCell(r.cells, addressAliases) ?? '-';
    final cep = pickCell(r.cells, zipAliases) ?? '-';
    final code = pickCell(r.cells, spxAliases) ?? '-';
    return 'CEP $cep | $code | ${addr.length > 55 ? '${addr.substring(0, 55)}…' : addr}';
  }).join('\n    ');
  return [label, file.path, rows.length, sample];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDFs reais da cliente (RJ) — extração + contagem', () async {
    final results = <List<dynamic>>[];
    results.add(await _importPdf(_protocoloPath, 'Protocolo de Carregamento'));
    results.add(await _importPdf(_relatorioPath, 'Relatório de Entregas'));
    results.add(await _importPdf(_loggiPacotesPath, 'Loggi Controle de Pacotes'));
    results.add(await _importPdf(_magalogAna2Path, 'Magalog ana inacio 2'));

    // ignore: avoid_print
    print('\n========== TESTE PDF REAL ==========');
    for (final r in results) {
      // ignore: avoid_print
      print('\n${r[0]}');
      // ignore: avoid_print
      print('  Arquivo: ${r[1]}');
      // ignore: avoid_print
      print('  Paradas importáveis: ${r[2]}');
      if (r[2] == 0) {
        // ignore: avoid_print
        print('  (nenhuma linha — conferir PDF ou parser)');
      } else {
        // ignore: avoid_print
        print('  Amostra (até 3):\n    ${r[3]}');
      }
    }
    // ignore: avoid_print
    print('\n====================================\n');

    for (final r in results) {
      expect(r[1], isNot('ARQUIVO_NAO_ENCONTRADO'), reason: 'Coloque os PDFs no caminho do teste');
      expect(r[2], greaterThan(0), reason: '${r[0]}: parser não encontrou entregas');
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
