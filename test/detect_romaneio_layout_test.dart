import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/services/excel_parser_service.dart';
import 'package:rota_prime/utils/detect_romaneio_layout.dart';

void main() {
  test('detecta PDF Protocolo vs Relatório', () {
    expect(
      detectRomaneioLayout(
        [
          ParsedRow(cells: {'Nº Entrega': '305557690', 'Endereço': 'RUA X'}, rawLine: ''),
        ],
        isPdf: true,
      ),
      ImportRomaneioLayout.pdfProtocoloEntrega,
    );
    expect(
      detectRomaneioLayout(
        [
          ParsedRow(cells: {'ID do Pacote': '563608526', 'Endereço Completo': 'Rua Y'}, rawLine: ''),
        ],
        isPdf: true,
      ),
      ImportRomaneioLayout.pdfRelatorioRj,
    );
  });

  test('detecta planilha Shopee com Sequence + tracking', () {
    final rows = List.generate(
      10,
      (i) => ParsedRow(
        cells: {
          'Sequence': '${i + 1}',
          'SPX TN': 'BR305${i.toString().padLeft(6, '0')}',
        },
        rawLine: '',
      ),
    );
    expect(
      detectRomaneioLayout(rows, isPdf: false),
      ImportRomaneioLayout.shopeeOrdemPacote,
    );
  });
}
