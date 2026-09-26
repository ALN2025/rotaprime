import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:rota_prime/mock/mock_paradas.dart';

/// Planilha XLSX de demonstração (90 linhas) para importação real.
Uint8List buildMockExcelBytes() {
  final excel = Excel.createExcel();
  final sheet = excel[excel.getDefaultSheet()!];

  sheet.appendRow([
    TextCellValue('AT ID'),
    TextCellValue('Sequence'),
    TextCellValue('Stop'),
    TextCellValue('SPX TN'),
    TextCellValue('Destination Address'),
    TextCellValue('Bairro'),
    TextCellValue('City'),
    TextCellValue('Zipcode'),
    TextCellValue('Latitude'),
    TextCellValue('Longitude'),
  ]);

  final mockStops = MockParadas.generate(rotaId: 0);
  for (final p in mockStops) {
    sheet.appendRow([
      TextCellValue('AT-${p.sequence}'),
      IntCellValue(p.sequence),
      IntCellValue(p.stop),
      TextCellValue(p.spxTn),
      TextCellValue(p.destinationAddress),
      TextCellValue(p.bairro),
      TextCellValue(p.city),
      TextCellValue(p.zipcode),
      TextCellValue(p.latitude?.toStringAsFixed(6) ?? ''),
      TextCellValue(p.longitude?.toStringAsFixed(6) ?? ''),
    ]);
  }

  final bytes = excel.encode();
  return Uint8List.fromList(bytes!);
}
