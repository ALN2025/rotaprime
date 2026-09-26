import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:rota_prime/utils/spx_regex.dart';

class ParsedRow {
  ParsedRow({required this.cells, required this.rawLine});

  final Map<String, String> cells;
  final String rawLine;
}

class ExcelParserService {
  List<ParsedRow> parse(Uint8List bytes, {String? fileName}) {
    if (bytes.isEmpty) {
      throw const FormatException('Arquivo vazio');
    }
    if (_shouldParseAsCsv(bytes, fileName)) {
      return _parseCsv(bytes);
    }
    return _parseXlsx(bytes);
  }

  static bool _shouldParseAsCsv(Uint8List bytes, String? fileName) {
    final n = (fileName ?? '').toLowerCase();
    if (n.endsWith('.csv')) return true;
    if (n.endsWith('.xlsx') || n.endsWith('.xls')) return false;
    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) return false;
    final sample = utf8.decode(bytes.take(512).toList(), allowMalformed: true);
    if (sample.contains('\t') || sample.contains(';') || sample.contains(',')) {
      return !sample.contains('<?xml') && !sample.startsWith('PK');
    }
    return false;
  }

  List<ParsedRow> _parseCsv(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final lines = text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];

    final delimiter = _detectDelimiter(lines.first);
    final headers = _splitCsvLine(lines.first, delimiter)
        .map((h) => h.trim())
        .toList();

    final rows = <ParsedRow>[];
    for (var r = 1; r < lines.length; r++) {
      final parts = _splitCsvLine(lines[r], delimiter);
      final cells = <String, String>{};
      final rawParts = <String>[];
      for (var c = 0; c < parts.length && c < headers.length; c++) {
        final key = headers[c].isEmpty ? 'col$c' : headers[c];
        final val = parts[c].trim();
        if (val.isNotEmpty) {
          cells[key] = val;
          rawParts.add(val);
        }
      }
      if (cells.isEmpty) continue;
      rows.add(ParsedRow(cells: cells, rawLine: rawParts.join('; ')));
    }
    return rows;
  }

  static String _detectDelimiter(String line) {
    final semi = ';'.allMatches(line).length;
    final comma = ','.allMatches(line).length;
    final tab = '\t'.allMatches(line).length;
    if (tab >= semi && tab >= comma && tab > 0) return '\t';
    if (semi >= comma && semi > 0) return ';';
    return ',';
  }

  static List<String> _splitCsvLine(String line, String delimiter) {
    final out = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (!inQuotes && ch == delimiter) {
        out.add(buf.toString());
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    out.add(buf.toString());
    return out;
  }

  List<ParsedRow> _parseXlsx(Uint8List bytes) {
    if (bytes.length < 4) {
      throw const FormatException('Arquivo vazio ou inválido');
    }
    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (e) {
      throw FormatException(
        'Não foi possível abrir o Excel. Salve como .xlsx (Excel 2007+) ou .csv. Detalhe: $e',
      );
    }
    if (excel.tables.isEmpty) return [];
    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) return [];

    final headerRow = sheet.rows.first;
    final headers = headerRow.map((c) => _cellText(c).trim()).toList();

    final rows = <ParsedRow>[];
    for (var r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      final cells = <String, String>{};
      final parts = <String>[];
      for (var c = 0; c < row.length && c < headers.length; c++) {
        final key = headers[c].isEmpty ? 'col$c' : headers[c];
        final val = _cellText(row[c]).trim();
        if (val.isNotEmpty) {
          cells[key] = val;
          parts.add(val);
        }
      }
      if (cells.isEmpty) continue;
      rows.add(ParsedRow(cells: cells, rawLine: parts.join('; ')));
    }
    return rows;
  }

  List<List<String>> previewColumns(Uint8List bytes, {int maxRows = 3, String? fileName}) {
    final parsed = parse(bytes, fileName: fileName);
    if (parsed.isEmpty) return [];
    final headers = parsed.first.cells.keys.toList();
    final result = <List<String>>[];
    for (var i = 0; i < parsed.length && result.length < maxRows; i++) {
      final cells = parsed[i].cells;
      result.add([
        for (final h in headers) '$h: ${cells[h] ?? '-'}',
      ]);
    }
    return result;
  }

  String _cellText(Data? cell) {
    if (cell == null) return '';
    final v = cell.value;
    if (v == null) return '';
    return v.toString();
  }

  static bool shouldAutoSelectColumn(String header, List<String> sampleValues) {
    final h = header.toLowerCase();
    if (h.contains('destination') || h.contains('endereço') || h.contains('address')) {
      return true;
    }
    if (h.contains('spx') || h.contains('tracking') || h.contains('tn')) {
      return true;
    }
    for (final s in sampleValues) {
      if (looksLikeTrackingCode(s)) return true;
    }
    return false;
  }
}
