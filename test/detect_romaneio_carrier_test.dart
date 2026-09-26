import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/services/excel_parser_service.dart';
import 'package:rota_prime/utils/detect_romaneio_carrier.dart';

void main() {
  test('PDF Protocolo de Carregamento → Magalog', () {
    final rows = [
      ParsedRow(
        cells: {
          'Transportadora': 'Magalog',
          'Nº Entrega': '307549232',
          'CEP': '26112055',
          'Endereço': 'RUA SAO JOSE 100',
        },
        rawLine: 'test',
      ),
    ];
    expect(
      detectRomaneioCarrier(rows, isPdf: true, pdfPlainText: 'Protocolo de Carregamento'),
      RomaneioCarrier.magalog,
    );
  });

  test('PDF Loggi — Transportadora + Prazo', () {
    final rows = [
      ParsedRow(
        cells: {
          'Transportadora': 'Loggi',
          'ID do Pacote': '565481711',
          'Prazo': '23/09/2026 22:00',
        },
        rawLine: 'test',
      ),
    ];
    expect(
      detectRomaneioCarrier(
        rows,
        isPdf: true,
        pdfPlainText: 'Relatório de Controle de Pacotes',
      ),
      RomaneioCarrier.loggi,
    );
  });
}
