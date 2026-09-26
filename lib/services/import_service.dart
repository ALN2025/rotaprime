import 'dart:typed_data';

import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/detect_romaneio_carrier.dart';
import 'package:rota_prime/utils/detect_romaneio_layout.dart';
import 'package:rota_prime/services/excel_parser_service.dart';
import 'package:rota_prime/services/romaneio_parser_service.dart';
import 'package:rota_prime/services/geocode_service.dart';
import 'package:rota_prime/utils/column_matcher.dart';
import 'package:rota_prime/utils/brazil_cep_uf.dart';
import 'package:rota_prime/utils/delivery_address_core.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';
import 'package:rota_prime/utils/parada_packages.dart';
import 'package:rota_prime/utils/import_romaneio_ref.dart';
import 'package:rota_prime/utils/import_parada_dedupe.dart';
import 'package:rota_prime/utils/import_row_filters.dart';

class ImportProgress {
  ImportProgress({
    required this.message,
    this.done = -1,
    this.total = 0,
  });

  /// Contador na UI; `-1` = só mensagem (sem "0/N").
  final int done;
  final int total;
  final String message;
}

typedef ImportProgressCallback = void Function(ImportProgress progress);

class RomaneioImportResult {
  const RomaneioImportResult({
    required this.paradas,
    required this.layout,
    required this.packagesImported,
    required this.linesParsed,
    required this.skippedByStatus,
    required this.pdfDuplicatesRemoved,
  });

  final List<Parada> paradas;
  final ImportRomaneioLayout layout;
  /// Pacotes que entram na rota (após filtros e dedupe).
  final int packagesImported;
  final int linesParsed;
  final int skippedByStatus;
  final int pdfDuplicatesRemoved;

  String get summaryLabel {
    final buf = StringBuffer('$packagesImported pacotes importados');
    if (skippedByStatus > 0) {
      buf.write(' ($skippedByStatus ignorados no status)');
    }
    if (pdfDuplicatesRemoved > 0) {
      buf.write(' ($pdfDuplicatesRemoved duplicados no PDF)');
    }
    return buf.toString();
  }
}

class ImportService {
  ImportService({RomaneioParserService? parser, GeocodeService? geocode})
      : _parser = parser ?? RomaneioParserService(),
        _geocode = geocode ?? GeocodeService();

  final RomaneioParserService _parser;
  final GeocodeService _geocode;

  Future<List<String>> headersFromBytes(Uint8List bytes, {String? fileName}) async {
    if (bytes.isEmpty) return [];
    final rows = await _parser.parseRows(bytes, fileName: fileName);
    if (rows.isEmpty) return [];
    return rows.first.cells.keys.toList();
  }

  Future<List<Map<String, String>>> previewRowsFromBytes(
    Uint8List bytes, {
    int limit = 3,
    String? fileName,
  }) async {
    if (bytes.isEmpty) return [];
    final parsed = await _parser.parseRows(bytes, fileName: fileName);
    final raw = parsed.take(limit).map((r) => Map<String, String>.from(r.cells)).toList();
    return normalizeImportPreviewRows(raw);
  }

  Future<void> geocodeParadas(
    List<Parada> paradas, {
    ImportProgressCallback? onProgress,
  }) =>
      _geocodeMissing(paradas, onProgress: onProgress);

  static String _cityForImport(String fromSheet, String zip) {
    final c = fromSheet.trim();
    if (c.isNotEmpty) return c;
    final z = zip.replaceAll(RegExp(r'\D'), '');
    final uf = ufFromBrazilCep(z);
    if (uf != null && uf.isNotEmpty) {
      final name = defaultCityLabelForUf(uf);
      if (name.isNotEmpty) return '$name/$uf';
    }
    return '';
  }

  /// Planilha ou PDF: códigos e endereços vêm do arquivo (não inventa ++ / Caxias).
  Future<RomaneioImportResult> buildParadas({
    required int rotaId,
    required Uint8List bytes,
    String? fileName,
    ImportProgressCallback? onProgress,
    bool geocode = true,
  }) async {
    final isPdf = RomaneioParserService.isPdf(bytes, fileName: fileName);
    if (isPdf) {
      onProgress?.call(ImportProgress(message: 'Preparando importação do PDF…'));
    }

    final parsed = bytes.isEmpty
        ? <ParsedRow>[]
        : await _parser.parseRows(
            bytes,
            fileName: fileName,
            onPhase: (msg) => onProgress?.call(ImportProgress(message: msg)),
          );
    if (parsed.isEmpty) {
      throw StateError('Planilha vazia ou inválida');
    }

    onProgress?.call(ImportProgress(
      message: isPdf
          ? '${parsed.length} pacotes lidos no PDF — validando…'
          : '${parsed.length} linhas na planilha — montando lista…',
    ));

    final layout = detectRomaneioLayout(parsed, isPdf: isPdf);
    final carrier = detectRomaneioCarrier(
      parsed,
      isPdf: isPdf,
      fileName: fileName,
    );

    final paradas = <Parada>[];
    var displayOrder = 0;
    var skippedByStatus = 0;
    for (var i = 0; i < parsed.length; i++) {
      final row = parsed[i];
      if (shouldSkipRomaneioRow(row.cells)) {
        skippedByStatus++;
        continue;
      }
      displayOrder++;
      final address = pickCell(row.cells, addressAliases) ?? '';
      final bairro = pickCell(row.cells, bairroAliases) ?? '';
      final zip = pickCell(row.cells, zipAliases) ?? '';
      final city = _cityForImport(pickCell(row.cells, cityAliases) ?? '', zip);
      final seq = importRomaneioSequence(row.cells, displayOrder);
      final stop = int.tryParse(pickCell(row.cells, stopAliases) ?? '') ?? 0;
      final latStr = pickCell(row.cells, latAliases);
      final lngStr = pickCell(row.cells, lngAliases);

      final tracking = importRomaneioTracking(row.cells, carrier: carrier);
      final prazo = (pickCell(row.cells, const ['Prazo', 'Prazo entrega', 'Deadline']) ?? '')
          .trim();

      paradas.add(Parada()
        ..rotaId = rotaId
        ..sequence = seq
        ..stop = stop
        ..spxTn = tracking
        ..prazoEntrega = prazo
        ..romaneioLayout = layout
        ..romaneioCarrier = carrier
        ..destinationAddress = address.isNotEmpty ? address : row.rawLine
        ..bairro = bairro
        ..city = city
        ..zipcode = zip
        ..latitude = double.tryParse(latStr?.replaceAll(',', '.') ?? '')
        ..longitude = double.tryParse(lngStr?.replaceAll(',', '.') ?? '')
        ..rawLine = row.rawLine
        ..ordemExibicao = displayOrder
        ..quantidadePacotes = isPdf ? 1 : parsePackageQtyFromCells(row.cells)
        ..entregue = false
        ..falha = false);

      final tickEvery = isPdf ? 5 : 40;
      if (displayOrder % tickEvery == 0 || displayOrder == parsed.length) {
        onProgress?.call(ImportProgress(
          done: displayOrder,
          total: parsed.length,
          message: isPdf ? 'Montando entregas do PDF' : 'Lendo linhas da planilha',
        ));
        await Future<void>.delayed(Duration.zero);
      }
    }

    if (paradas.isEmpty) {
      throw StateError(
        'Nenhum pacote pendente no romaneio. '
        'Linhas já entregues/canceladas (quando houver coluna Status) são ignoradas.',
      );
    }

    var pdfDuplicatesRemoved = 0;
    if (isPdf) {
      final dedupe = dedupeImportParadas(List<Parada>.from(paradas));
      pdfDuplicatesRemoved = dedupe.duplicatesRemoved;
      paradas
        ..clear()
        ..addAll(dedupe.paradas);
    }

    if (paradas.isEmpty) {
      throw StateError('Nenhuma entrega válida após ler o PDF.');
    }

    finalizePackageQtyFromImport(paradas);
    final packagesImported = sumPackageUnits(paradas);

    onProgress?.call(ImportProgress(
      done: packagesImported,
      total: packagesImported,
      message: isPdf
          ? '$packagesImported pacotes no romaneio (contagem exata)'
          : '$packagesImported pacotes na planilha',
    ));

    final needsGeocode = paradas.any(
      (p) =>
          p.latitude == null &&
          p.longitude == null &&
          p.destinationAddress.trim().isNotEmpty,
    );
    if (geocode && needsGeocode) {
      await _geocodeMissing(paradas, onProgress: onProgress);
    } else {
      onProgress?.call(ImportProgress(message: 'Salvando entregas…'));
    }
    return RomaneioImportResult(
      paradas: paradas,
      layout: layout,
      packagesImported: packagesImported,
      linesParsed: parsed.length,
      skippedByStatus: skippedByStatus,
      pdfDuplicatesRemoved: pdfDuplicatesRemoved,
    );
  }

  static String _geocodeGroupKey(Parada p) => deliveryAddressKey(p);

  /// Só endereços distintos (1 chamada por casa/apto), não 1 por pacote.
  Future<void> _geocodeMissing(
    List<Parada> paradas, {
    ImportProgressCallback? onProgress,
  }) async {
    final byKey = <String, List<Parada>>{};
    for (final p in paradas) {
      if (p.latitude != null && p.longitude != null) continue;
      if (p.destinationAddress.trim().isEmpty) continue;
      byKey.putIfAbsent(_geocodeGroupKey(p), () => []).add(p);
    }

    final keys = byKey.keys.toList();
    if (keys.isEmpty) return;

    final n = keys.length;
    final etaSec = (n * 1.15).ceil();
    onProgress?.call(ImportProgress(
      message: 'Localizando $n endereço${n == 1 ? '' : 's'} no mapa '
          '(~$etaSec s — normal em PDF/planilha nova)…',
    ));

    _geocode.clearImportGeocodeCache();

    final coords = <String, (double, double)>{};
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final sample = byKey[key]!.first;

      GeocodeResult g;
      try {
        g = await _geocode
            .geocodeParadaForImport(sample)
            .timeout(const Duration(seconds: 22));
      } catch (_) {
        g = GeocodeResult.fallback();
      }
      if (!g.found) {
        final raw = sample.rawLine.trim();
        final q = raw.isNotEmpty ? raw : geocodeQueryForParada(sample);
        if (q.isNotEmpty) {
          try {
            g = await _geocode
                .geocode(
                  q,
                  allowFallback: false,
                  cityHint: sample.city.trim().isNotEmpty
                      ? sample.city
                      : paradaCityAndUf(sample).city,
                )
                .timeout(const Duration(seconds: 18));
          } catch (_) {
            g = GeocodeResult.fallback();
          }
        }
      }
      if (g.found) {
        coords[key] = (g.lat, g.lng);
      }

      onProgress?.call(ImportProgress(
        done: i + 1,
        total: n,
        message: 'Endereços no mapa',
      ));

      if (i % 2 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    for (final entry in byKey.entries) {
      final c = coords[entry.key];
      if (c == null) continue;
      for (final p in entry.value) {
        p.latitude = c.$1;
        p.longitude = c.$2;
      }
    }

    final stillMissing = paradas
        .where((p) =>
            p.latitude == null &&
            p.longitude == null &&
            p.destinationAddress.trim().isNotEmpty)
        .toList();

    if (stillMissing.isEmpty) {
      onProgress?.call(ImportProgress(message: 'Salvando entregas…'));
      return;
    }

    // 2ª passagem rápida (com progresso). A rota segue mesmo se faltar GPS —
    // o app tenta de novo depois em background.
    const maxSecondPass = 30;
    const passBudget = Duration(seconds: 50);
    final todo = stillMissing.length > maxSecondPass
        ? stillMissing.take(maxSecondPass).toList()
        : stillMissing;
    final deadline = DateTime.now().add(passBudget);

    onProgress?.call(ImportProgress(
      done: 0,
      total: todo.length,
      message: 'Ajuste fino no mapa',
    ));

    for (var i = 0; i < todo.length; i++) {
      if (DateTime.now().isAfter(deadline)) break;
      final p = todo[i];
      try {
        var g = await _geocode
            .geocodeParadaForImport(p)
            .timeout(const Duration(seconds: 14));
        if (!g.found) {
          final q = geocodeQueryForParada(p);
          if (q.isNotEmpty) {
            g = await _geocode
                .geocode(
                  q,
                  allowFallback: true,
                  cityHint: p.city.trim().isNotEmpty
                      ? p.city
                      : paradaCityAndUf(p).city,
                )
                .timeout(const Duration(seconds: 10));
          }
        }
        if (g.found) {
          p.latitude = g.lat;
          p.longitude = g.lng;
        }
      } catch (_) {}

      onProgress?.call(ImportProgress(
        done: i + 1,
        total: todo.length,
        message: 'Ajuste fino no mapa',
      ));
      if (i % 2 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    onProgress?.call(ImportProgress(message: 'Salvando entregas…'));
  }
}
