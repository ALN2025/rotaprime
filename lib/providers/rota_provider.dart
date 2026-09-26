import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:latlong2/latlong.dart';
import 'package:rota_prime/mock/mock_paradas.dart';
import 'package:rota_prime/models/gasto.dart';
import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/rota.dart';
import 'package:rota_prime/models/historico_item.dart';
import 'package:rota_prime/services/delivery_cockpit_service.dart';
import 'package:rota_prime/services/geocode_service.dart';
import 'package:rota_prime/services/import_service.dart';
import 'package:rota_prime/services/map_tile_prefetch.dart';
import 'package:rota_prime/services/isar_service.dart';
import 'package:rota_prime/services/location_service.dart';
import 'package:rota_prime/services/osrm_service.dart';
import 'package:rota_prime/services/settings_persistence.dart';
import 'package:rota_prime/utils/import_parada_dedupe.dart';
import 'package:rota_prime/utils/romaneio_import_registry.dart';
import 'package:rota_prime/utils/manifest_route_order.dart';
import 'package:rota_prime/utils/navigation_parada_utils.dart';
import 'package:rota_prime/utils/route_delivery_stats.dart';
import 'package:rota_prime/utils/stop_route_order.dart';
import 'package:rota_prime/utils/navigation_route_leg.dart';
import 'package:rota_prime/utils/route_points_display.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/config/plan_limits.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';
import 'package:rota_prime/utils/limpar_endereco.dart';
import 'package:rota_prime/utils/rota_titulo.dart';
import 'package:rota_prime/utils/spx_regex.dart';

const _routeDistance = Distance();

/// GPS do emulador (EUA) ou longe do romaneio não deve quebrar OSRM no Brasil.
bool _driverOriginPlausibleForStops(LatLng? driver, List<Parada> paradas) {
  if (driver == null) return false;
  final withCoords = paradas.where((p) => p.latitude != null && p.longitude != null);
  if (withCoords.isEmpty) return true;
  var sumLat = 0.0;
  var sumLng = 0.0;
  var n = 0;
  for (final p in withCoords) {
    sumLat += p.latitude!;
    sumLng += p.longitude!;
    n++;
  }
  final center = LatLng(sumLat / n, sumLng / n);
  final km = _routeDistance.as(LengthUnit.Kilometer, driver, center);
  return km <= 200;
}

final isarProvider = FutureProvider<Isar>((ref) => IsarService.instance);

class RotaState {
  const RotaState({
    this.rotaId,
    this.paradas = const [],
    this.gastos = const [],
    this.rota,
    this.routePoints = const [],
    this.excelBytes,
    this.selectedColumns = const {},
    this.pacotesEscaneados = 0,
    this.statusMessage = '',
    this.driverPosition,
    this.driverHeading = 0,
    this.useGpsOrigin = true,
    this.importFileName,
    this.pendingRouteScheduledAt,
    this.pendingRouteLabel,
    this.pendingImportCachePath,
    this.navigationTargetParadaId,
    this.navigationLegPoints = const [],
    this.optimizeProgress = 0,
    this.routeActiveSince,
    this.pendingMergeImport = false,
  });

  final int? rotaId;
  final List<Parada> paradas;
  final List<Gasto> gastos;
  final RotaRecord? rota;
  final List<LatLng> routePoints;
  final Uint8List? excelBytes;
  final Set<String> selectedColumns;
  final int pacotesEscaneados;
  final String statusMessage;
  final LatLng? driverPosition;
  final double driverHeading;
  final bool useGpsOrigin;
  final String? importFileName;
  final DateTime? pendingRouteScheduledAt;
  final String? pendingRouteLabel;
  final String? pendingImportCachePath;
  /// Parada ativa no mapa de entrega (manual ou mais próxima).
  final int? navigationTargetParadaId;
  /// Trecho desenhado no mapa — só até a parada ativa.
  final List<LatLng> navigationLegPoints;
  /// 0–1 durante otimização PRO (barra de progresso).
  final double optimizeProgress;
  /// Relógio da rota em andamento (após INICIAR ROTA).
  final DateTime? routeActiveSince;
  /// Acrescentar próximo arquivo à rota atual (Magalog + Loggi + …).
  final bool pendingMergeImport;

  /// Pacotes marcados como entregues (linhas).
  int get entregues => RouteDeliveryStats.deliveredPackages(paradas);

  int get totalParadas => RouteDeliveryStats.totalStops(paradas);

  int get totalPacotes => RouteDeliveryStats.packageDenominator(
        paradas,
        importedTotal: _importedPackageTotal,
      );

  int get _importedPackageTotal {
    final n = rota?.pacotesImportados ?? 0;
    return n > 0 ? n : 0;
  }

  int get paradasConcluidas => RouteDeliveryStats.completedStops(paradas);

  /// Romaneio/planilha — não mostrar “adicionar manual” no mapa da rota importada.
  bool get isSpreadsheetImportedRoute {
    final file = rota?.arquivoPlanilhaImportada;
    if (file != null && file.trim().isNotEmpty) return true;
    if (importFileName != null && importFileName!.trim().isNotEmpty) return true;
    if (excelBytes != null && excelBytes!.isNotEmpty) return true;
    return false;
  }

  bool get allowManualParadaEntry => !isSpreadsheetImportedRoute;

  RotaState copyWith({
    int? rotaId,
    List<Parada>? paradas,
    List<Gasto>? gastos,
    RotaRecord? rota,
    List<LatLng>? routePoints,
    Uint8List? excelBytes,
    Set<String>? selectedColumns,
    int? pacotesEscaneados,
    String? statusMessage,
    LatLng? driverPosition,
    double? driverHeading,
    bool? useGpsOrigin,
    String? importFileName,
    DateTime? pendingRouteScheduledAt,
    String? pendingRouteLabel,
    String? pendingImportCachePath,
    int? navigationTargetParadaId,
    List<LatLng>? navigationLegPoints,
    bool clearNavigationTarget = false,
    double? optimizeProgress,
    DateTime? routeActiveSince,
    bool clearRouteActiveSince = false,
    bool? pendingMergeImport,
  }) {
    return RotaState(
      rotaId: rotaId ?? this.rotaId,
      paradas: paradas ?? this.paradas,
      gastos: gastos ?? this.gastos,
      rota: rota ?? this.rota,
      routePoints: routePoints ?? this.routePoints,
      excelBytes: excelBytes ?? this.excelBytes,
      selectedColumns: selectedColumns ?? this.selectedColumns,
      pacotesEscaneados: pacotesEscaneados ?? this.pacotesEscaneados,
      statusMessage: statusMessage ?? this.statusMessage,
      driverPosition: driverPosition ?? this.driverPosition,
      driverHeading: driverHeading ?? this.driverHeading,
      useGpsOrigin: useGpsOrigin ?? this.useGpsOrigin,
      importFileName: importFileName ?? this.importFileName,
      pendingRouteScheduledAt: pendingRouteScheduledAt ?? this.pendingRouteScheduledAt,
      pendingRouteLabel: pendingRouteLabel ?? this.pendingRouteLabel,
      pendingImportCachePath: pendingImportCachePath ?? this.pendingImportCachePath,
      navigationTargetParadaId: clearNavigationTarget
          ? null
          : (navigationTargetParadaId ?? this.navigationTargetParadaId),
      navigationLegPoints: navigationLegPoints ?? this.navigationLegPoints,
      optimizeProgress: optimizeProgress ?? this.optimizeProgress,
      routeActiveSince: clearRouteActiveSince
          ? null
          : (routeActiveSince ?? this.routeActiveSince),
      pendingMergeImport: pendingMergeImport ?? this.pendingMergeImport,
    );
  }
}

String optimizeStatusForUser(String raw, int step, int total) {
  final pct = total > 0 ? ((step / total) * 100).clamp(0, 99).round() : 0;
  final lower = raw.toLowerCase();
  if (lower.contains('ordenando') || lower.contains('trip') || lower.contains('table')) {
    return 'Organizando a ordem das paradas… $pct%';
  }
  if (lower.contains('route') || lower.contains('trajeto') || lower.contains('trecho')) {
    return 'Desenhando o caminho nas ruas… $pct%';
  }
  if (lower.contains('gps')) {
    return raw;
  }
  return 'Calculando rota (internet)… $pct%';
}

class RotaNotifier extends StateNotifier<RotaState> {
  RotaNotifier(this._ref) : super(const RotaState());

  final Ref _ref;
  final _geocode = GeocodeService();
  final _osrm = OsrmService();
  final _import = ImportService();
  final _location = LocationService();
  static const _distance = Distance();
  static const _legRefreshMinMoveMeters = 12.0;
  static const _legOffRouteMeters = 50.0;
  LatLng? _lastLegOrigin;
  bool get _isPro => _ref.read(subscriptionProvider).isPro;

  Future<bool> _ensureProEntitlementsLoaded() async {
    await _ref.read(subscriptionProvider.notifier).load();
    return _ref.read(subscriptionProvider).isPro;
  }

  /// Trial PRO e licença PRO — mesmas funções PRO (otimizar, trecho OSRM, mais próximo).
  bool get _isProEntitled => _isPro;

  /// Polyline da rota inteira (visão geral) — só depois de Otimizar.
  bool get _showOptimizedRoutePolyline {
    final rota = state.rota;
    if (rota == null) return false;
    return _isPro && rota.otimizada == true;
  }

  /// Trecho laranja GPS → pin (OSRM) — Trial PRO e PRO licenciado.
  bool get _showNavigationLeg => _isProEntitled;

  /// Grátis: ordem da planilha. Trial/PRO: GPS → mais próximo (ou toque no pin).
  static bool useNearestNavigation(RotaState state, {required bool isPro}) => isPro;

  bool get _useNearestNavigation => useNearestNavigation(state, isPro: _isPro);

  /// Linha laranja pelas ruas (OSRM) só no PRO com rota otimizada persistida.
  List<LatLng> _displayRoutePoints(RotaRecord? rota, List<LatLng> loaded) {
    if (!_isPro || rota?.otimizada != true || loaded.length < 2) {
      return const [];
    }
    return loaded;
  }

  Future<void> loadRota(int rotaId) async {
    final isar = await IsarService.instance;
    final rota = await isar.rotaRecords.get(rotaId);
    if (rota == null) {
      throw StateError('Rota não encontrada. Ela pode ter sido excluída.');
    }
    var paradas =
        await isar.paradas.filter().rotaIdEqualTo(rotaId).sortByOrdemExibicao().findAll();
    final gastos = await isar.gastos.filter().rotaIdEqualTo(rotaId).findAll();

    var persistRepair = false;
    for (var i = 0; i < paradas.length; i++) {
      if (paradas[i].ordemExibicao < 1) {
        paradas[i].ordemExibicao = i + 1;
        persistRepair = true;
      }
    }
    if (paradas.isNotEmpty) {
      final livePkg = RouteDeliveryStats.totalPackages(paradas);
      final liveStops = RouteDeliveryStats.totalStops(paradas);
      if (rota.pacotesImportados != livePkg || rota.paradasImportadas != liveStops) {
        rota.pacotesImportados = livePkg;
        rota.paradasImportadas = liveStops;
        persistRepair = true;
      }
    }
    if (persistRepair) {
      await isar.writeTxn(() async {
        await isar.paradas.putAll(paradas);
        await isar.rotaRecords.put(rota);
      });
    }
    List<LatLng> points = [];
    final geomJson = rota.rotaGeometriaJson;
    if (rota.status != RotaStatus.finalizada &&
        geomJson != null &&
        geomJson.isNotEmpty) {
      try {
        final list = jsonDecode(geomJson) as List<dynamic>;
        points = list
            .map((e) => LatLng((e[0] as num).toDouble(), (e[1] as num).toDouble()))
            .toList();
        points = routePointsForDisplay(points, rota);
      } catch (_) {
        points = const [];
      }
    }
    LatLng? driver;
    if (rota.origemLatitude != null && rota.origemLongitude != null) {
      driver = LatLng(rota.origemLatitude!, rota.origemLongitude!);
    }
    final isLiveDelivery = rota.status == RotaStatus.ativa;
    state = state.copyWith(
      rotaId: rotaId,
      rota: rota,
      paradas: paradas,
      gastos: gastos,
      routePoints: _displayRoutePoints(rota, points),
      driverPosition: driver,
      navigationLegPoints: const [],
      clearNavigationTarget: !isLiveDelivery,
      routeActiveSince: isLiveDelivery ? rota.criadaEm : null,
      clearRouteActiveSince: !isLiveDelivery,
    );
    await stripRouteTraceUnlessProOptimized();
    unawaited(fillMissingGeocodesForCurrentRoute());
  }

  /// Paradas sem GPS após import — tenta localizar de novo (mapa 1 pin por pacote).
  Future<void> fillMissingGeocodesForCurrentRoute() async {
    if (state.paradas.isEmpty) return;
    final missing = state.paradas
        .where((p) =>
            (p.latitude == null || p.longitude == null) &&
            p.destinationAddress.trim().isNotEmpty)
        .toList();
    if (missing.isEmpty) return;
    try {
      await _import.geocodeParadas(missing);
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.paradas.putAll(state.paradas);
      });
      state = state.copyWith(paradas: List<Parada>.from(state.paradas));
    } catch (_) {}
  }

  /// Retoma rota com status [RotaStatus.ativa] (app reaberto ou processo morto).
  Future<bool> tryResumeActiveRoute() async {
    final isar = await IsarService.instance;
    final ativa = await isar.rotaRecords
        .filter()
        .statusEqualTo(RotaStatus.ativa)
        .sortByCriadaEmDesc()
        .findFirst();
    if (ativa == null) return false;
    await loadRota(ativa.id);
    return state.rota?.status == RotaStatus.ativa && state.paradas.isNotEmpty;
  }

  Future<bool> loadLatestDraft() async {
    final isar = await IsarService.instance;
    final draft = await isar.rotaRecords
        .filter()
        .statusEqualTo(RotaStatus.rascunho)
        .sortByCriadaEmDesc()
        .findFirst();
    if (draft == null) {
      final ativa = await isar.rotaRecords
          .filter()
          .statusEqualTo(RotaStatus.ativa)
          .sortByCriadaEmDesc()
          .findFirst();
      if (ativa == null) return false;
      await loadRota(ativa.id);
      return true;
    }
    await loadRota(draft.id);
    return true;
  }

  Future<List<RotaRecord>> loadRotasSalvas() async {
    final isar = await IsarService.instance;
    unawaited(_purgeEmptyDraftRoutes(isar, keepRotaId: state.rotaId));
    final all = await isar.rotaRecords.where().findAll();
    all.sort((a, b) {
      final da = a.finalizadaEm ?? a.criadaEm;
      final db = b.finalizadaEm ?? b.criadaEm;
      return db.compareTo(da);
    });
    final visible = <RotaRecord>[];
    for (final r in all) {
      if (r.status == RotaStatus.finalizada || r.status == RotaStatus.ativa) {
        visible.add(r);
        continue;
      }
      if (r.status == RotaStatus.rascunho) {
        final count = await isar.paradas.filter().rotaIdEqualTo(r.id).count();
        if (count > 0) visible.add(r);
      }
    }
    return visible;
  }

  Future<int> _paradaCountForRota(Isar isar, int rotaId) =>
      isar.paradas.filter().rotaIdEqualTo(rotaId).count();

  /// Remove rascunhos vazios duplicados (0 paradas) — um fluxo = um rascunho.
  Future<void> _purgeEmptyDraftRoutes(Isar isar, {int? keepRotaId}) async {
    final drafts = await isar.rotaRecords
        .filter()
        .statusEqualTo(RotaStatus.rascunho)
        .findAll();
    final deleteIds = <int>[];
    for (final r in drafts) {
      if (keepRotaId != null && r.id == keepRotaId) continue;
      final count = await _paradaCountForRota(isar, r.id);
      if (count == 0) deleteIds.add(r.id);
    }
    if (deleteIds.isEmpty) return;
    await isar.writeTxn(() async {
      for (final id in deleteIds) {
        await isar.paradas.filter().rotaIdEqualTo(id).deleteAll();
        await isar.gastos.filter().rotaIdEqualTo(id).deleteAll();
        await isar.rotaRecords.delete(id);
      }
    });
  }

  Future<int?> _latestEmptyDraftId(Isar isar) async {
    final drafts = await isar.rotaRecords
        .filter()
        .statusEqualTo(RotaStatus.rascunho)
        .sortByCriadaEmDesc()
        .findAll();
    for (final d in drafts) {
      final count = await _paradaCountForRota(isar, d.id);
      if (count == 0) return d.id;
    }
    return null;
  }

  void applySelectedColumns(Set<String> columns, {bool persist = true}) {
    state = state.copyWith(selectedColumns: columns);
    if (persist) _persistLocalSettings();
  }

  Future<List<HistoricoItem>> loadHistorico() async {
    final isar = await IsarService.instance;
    final rotas = await isar.rotaRecords
        .filter()
        .statusEqualTo(RotaStatus.finalizada)
        .sortByCriadaEmDesc()
        .findAll();
    final items = <HistoricoItem>[];
    for (final r in rotas) {
      final count = await isar.paradas.filter().rotaIdEqualTo(r.id).count();
      items.add(HistoricoItem(
        id: r.id,
        titulo: r.titulo,
        paradasCount: count,
        criadaEm: r.criadaEm,
        finalizadaEm: r.finalizadaEm,
      ));
    }
    return items;
  }

  Future<void> refreshDriverLocation() async {
    state = state.copyWith(statusMessage: 'Obtendo localização GPS…');
    final fix = await _location.getCurrentFix();
    state = state.copyWith(
      driverPosition: fix?.position,
      driverHeading: fix?.headingDegrees ?? state.driverHeading,
      statusMessage: '',
    );
  }

  void updateDriverLive(LatLng position, {required double headingDegrees}) {
    state = state.copyWith(
      driverPosition: position,
      driverHeading: headingDegrees,
    );
  }

  void setUseGpsOrigin(bool value, {bool persist = true}) {
    state = state.copyWith(useGpsOrigin: value);
    if (persist) _persistLocalSettings();
  }

  void _persistLocalSettings() {
    Future.microtask(() => persistAllSettings(_ref));
  }

  Future<void> deleteRotaById(int rotaId) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.paradas.filter().rotaIdEqualTo(rotaId).deleteAll();
      await isar.gastos.filter().rotaIdEqualTo(rotaId).deleteAll();
      await isar.rotaRecords.delete(rotaId);
    });
    if (state.rotaId == rotaId) {
      state = const RotaState();
    }
  }

  Future<void> deleteCurrentRoute() async {
    final rotaId = state.rotaId;
    if (rotaId == null) return;
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.paradas.filter().rotaIdEqualTo(rotaId).deleteAll();
      await isar.gastos.filter().rotaIdEqualTo(rotaId).deleteAll();
      await isar.rotaRecords.delete(rotaId);
    });
    state = const RotaState();
  }

  void setExcelBytes(Uint8List bytes, {String? fileName}) {
    state = state.copyWith(excelBytes: bytes, importFileName: fileName);
  }

  /// Grava planilha em cache local (sobrevive ao voltar do seletor do Android).
  static String _importCacheFileName(String? fileName) {
    final n = (fileName ?? '').toLowerCase();
    if (n.endsWith('.csv')) return 'rota_prime_import.csv';
    if (n.endsWith('.pdf')) return 'rota_prime_import.pdf';
    if (n.endsWith('.xls')) return 'rota_prime_import.xls';
    return 'rota_prime_import.xlsx';
  }

  Future<void> setExcelBytesPersisted(Uint8List bytes, {String? fileName}) async {
    final label = fileName?.trim().isNotEmpty == true ? fileName!.trim() : 'romaneio.xlsx';
    state = state.copyWith(excelBytes: bytes, importFileName: label);
    try {
      final dir = await getTemporaryDirectory();
      final cache = File('${dir.path}/${_importCacheFileName(label)}');
      await cache.writeAsBytes(bytes, flush: true);
      state = state.copyWith(pendingImportCachePath: cache.path);
    } catch (_) {
      // memória ainda tem bytes
    }
  }

  /// Nova importação: guarda planilha e limpa rota anterior em memória (mantém data/nome).
  Future<void> prepareNewImportFromBytes(Uint8List bytes, {String? fileName}) async {
    if (state.rotaId != null && state.paradas.isNotEmpty) {
      return prepareMergeImportFromBytes(bytes, fileName: fileName);
    }
    final useGps = state.useGpsOrigin;
    await setExcelBytesPersisted(bytes, fileName: fileName);
    final label = state.importFileName;
    final preview = await _import.previewRowsFromBytes(bytes, limit: 1, fileName: label);
    if (preview.isEmpty) {
      state = RotaState(useGpsOrigin: useGps);
      throw StateError(
        'Arquivo sem linhas de entrega. Use romaneio .xlsx/.csv ou PDF '
        '(texto selecionável — Shopee, ML, Amazon, transportadoras).',
      );
    }
    state = RotaState(
      excelBytes: state.excelBytes,
      importFileName: state.importFileName,
      pendingImportCachePath: state.pendingImportCachePath,
      useGpsOrigin: useGps,
      selectedColumns: const {},
    );
    applySelectedColumns(const {}, persist: false);
  }

  /// Soma outro romaneio (PDF/planilha) à rota aberta — ex.: 41 Magalog + 20 Loggi.
  Future<void> prepareMergeImportFromBytes(Uint8List bytes, {String? fileName}) async {
    if (state.rotaId == null) {
      throw StateError('Crie ou abra uma rota antes de adicionar outro romaneio.');
    }
    await setExcelBytesPersisted(bytes, fileName: fileName);
    final label = state.importFileName;
    final preview = await _import.previewRowsFromBytes(bytes, limit: 1, fileName: label);
    if (preview.isEmpty) {
      throw StateError(
        'Arquivo sem linhas de entrega. Use planilha .xlsx ou PDF com texto.',
      );
    }
    state = state.copyWith(
      pendingMergeImport: true,
      selectedColumns: const {},
    );
    applySelectedColumns(const {}, persist: false);
  }

  Future<Uint8List?> resolveExcelBytes() async {
    final mem = state.excelBytes;
    if (mem != null && mem.isNotEmpty) return mem;
    final path = state.pendingImportCachePath;
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      state = state.copyWith(excelBytes: bytes);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  void setPendingRouteCreation({required DateTime scheduledAt, String? label}) {
    state = state.copyWith(
      pendingRouteScheduledAt: scheduledAt,
      pendingRouteLabel: label?.trim().isEmpty == true ? null : label?.trim(),
    );
  }

  /// Nova rota vazia para adicionar entregas manualmente (sem planilha).
  Future<void> prepareNewManualRoute({String? label}) async {
    clearWorkingRoute();
    setPendingRouteCreation(scheduledAt: DateTime.now(), label: label);
    await ensureEmptyDraftRota(forceNew: true);
  }

  DateTime get _scheduledForCreation {
    final pending = state.pendingRouteScheduledAt;
    if (pending != null) return pending;
    return DateTime.now();
  }

  String _tituloForNewRota() {
    return buildRotaTitulo(
      when: _scheduledForCreation,
      nomeOpcional: state.pendingRouteLabel,
      importFileName: state.importFileName,
    );
  }

  Future<void> ensureEmptyDraftRota({bool forceNew = false}) async {
    if (!forceNew && state.rotaId != null) return;

    final isar = await IsarService.instance;

    if (!forceNew) {
      final reuseId = await _latestEmptyDraftId(isar);
      if (reuseId != null) {
        await _purgeEmptyDraftRoutes(isar, keepRotaId: reuseId);
        await loadRota(reuseId);
        return;
      }
    } else {
      await _purgeEmptyDraftRoutes(isar, keepRotaId: null);
    }

    final when = _scheduledForCreation;
    final rota = RotaRecord()
      ..titulo = _tituloForNewRota()
      ..ownerEmail = ''
      ..status = RotaStatus.rascunho
      ..valorPago = 0
      ..kmInicial = 0
      ..criadaEm = when
      ..arquivoPlanilhaImportada = null;

    await isar.writeTxn(() async {
      await isar.rotaRecords.put(rota);
    });
    await _purgeEmptyDraftRoutes(isar, keepRotaId: rota.id);

    state = state.copyWith(
      rotaId: rota.id,
      rota: rota,
      paradas: const [],
      routePoints: const [],
    );
  }

  /// Sai da entrega ativa e volta ao planejamento (tela INICIAR ROTA).
  Future<void> returnToPlanningFromActive() async {
    final isar = await IsarService.instance;
    final rota = state.rota;
    if (rota != null && rota.status == RotaStatus.ativa) {
      rota.status = RotaStatus.rascunho;
      await isar.writeTxn(() async {
        await isar.rotaRecords.put(rota);
      });
      state = state.copyWith(rota: rota);
    }
  }

  Uint8List? get excelBytesOrNull {
    final current = state.excelBytes;
    if (current != null && current.isNotEmpty) return current;
    return null;
  }

  Future<List<Map<String, String>>> previewRowsForMapping() async {
    var bytes = state.excelBytes;
    if (bytes == null || bytes.isEmpty) {
      final path = state.pendingImportCachePath;
      if (path != null && path.isNotEmpty) {
        try {
          final file = File(path);
          if (file.existsSync()) {
            bytes = file.readAsBytesSync();
          }
        } catch (_) {}
      }
    }
    if (bytes != null && bytes.isNotEmpty) {
      final rows = await _import.previewRowsFromBytes(
        bytes,
        limit: 3,
        fileName: state.importFileName,
      );
      if (rows.isNotEmpty) return rows;
      throw StateError('Arquivo sem linhas de entrega.');
    }
    return MockParadas.previewRows();
  }

  void toggleColumn(String column, bool selected) {
    final cols = Set<String>.from(state.selectedColumns);
    if (selected) {
      cols.add(column);
    } else {
      cols.remove(column);
    }
    state = state.copyWith(selectedColumns: cols);
    _persistLocalSettings();
  }

  /// Mesmo nome de arquivo (Shopee): apaga rotas antigas — só vale a importação de agora.
  Future<void> _removeOlderRoutesSameSpreadsheet(
    Isar isar, {
    required String fileLabel,
    required int keepRotaId,
  }) async {
    final name = fileLabel.trim();
    if (name.isEmpty) return;
    final all = await isar.rotaRecords
        .filter()
        .arquivoPlanilhaImportadaEqualTo(name)
        .findAll();
    if (all.length <= 1) return;
    await isar.writeTxn(() async {
      for (final r in all) {
        if (r.id == keepRotaId) continue;
        if (r.status == RotaStatus.finalizada) continue;
        await isar.paradas.filter().rotaIdEqualTo(r.id).deleteAll();
        await isar.gastos.filter().rotaIdEqualTo(r.id).deleteAll();
        await isar.rotaRecords.delete(r.id);
      }
    });
  }

  /// Evita reabrir rota antiga “em andamento” depois de importar planilha nova.
  Future<void> _demoteOtherActiveRoutes(Isar isar, {required int keepRotaId}) async {
    final others = await isar.rotaRecords
        .filter()
        .statusEqualTo(RotaStatus.ativa)
        .findAll();
    if (others.isEmpty) return;
    await isar.writeTxn(() async {
      for (final r in others) {
        if (r.id == keepRotaId) continue;
        r.status = RotaStatus.rascunho;
        await isar.rotaRecords.put(r);
      }
    });
  }

  Future<int> importFromMapping() async {
    if (state.pendingMergeImport && state.rotaId != null && state.rota != null) {
      return _mergeImportIntoCurrentRota();
    }

    final isar = await IsarService.instance;
    final bytes = await resolveExcelBytes();
    if (bytes == null) {
      throw StateError('Nenhuma planilha selecionada. Importe um arquivo XLSX.');
    }

    final when = DateTime.now();
    state = state.copyWith(pendingRouteScheduledAt: when);
    final importLabel = state.importFileName?.trim();
    final rota = RotaRecord()
      ..titulo = buildRotaTitulo(
        when: when,
        nomeOpcional: state.pendingRouteLabel,
        importFileName: importLabel ?? state.importFileName,
      )
      ..ownerEmail = ''
      ..status = RotaStatus.rascunho
      ..valorPago = 0
      ..kmInicial = 0
      ..criadaEm = when
      ..duracaoMinutos = 0
      ..distanciaKm = 0
      ..otimizada = false
      ..rotaGeometriaJson = null
      ..arquivoPlanilhaImportada =
          (importLabel != null && importLabel.isNotEmpty) ? importLabel : 'planilha.xlsx';

    await isar.writeTxn(() async {
      await isar.rotaRecords.put(rota);
    });
    await _demoteOtherActiveRoutes(isar, keepRotaId: rota.id);

    state = state.copyWith(
      statusMessage: 'Lendo planilha…',
      rota: rota,
      rotaId: rota.id,
      paradas: const [],
      routePoints: const [],
      navigationLegPoints: const [],
      clearNavigationTarget: true,
    );

    List<Parada> paradas;
    try {
      if (await RomaneioImportRegistry.containsFile(rota.id, bytes)) {
        throw StateError(RomaneioImportRegistry.duplicateFileMessage);
      }
      state = state.copyWith(statusMessage: 'Lendo linhas da planilha…');
      final proUnlimited = await _ensureProEntitlementsLoaded();
      final imported = await _import.buildParadas(
        rotaId: rota.id,
        bytes: bytes,
        fileName: state.importFileName,
        geocode: true,
        onProgress: (p) {
          final suffix = p.total > 0 && p.done >= 0 ? ' (${p.done}/${p.total})' : '';
          state = state.copyWith(statusMessage: '${p.message}$suffix');
        },
      );
      paradas = imported.paradas;
      rota.romaneioLayout = imported.layout;
      final orderedPreview = orderParadasByManifestSequence(paradas);
      if (!proUnlimited && !PlanLimits.withinFreeRouteLimit(orderedPreview.length)) {
        throw StateError(PlanLimits.importOverLimitMessage(orderedPreview.length));
      }
    } catch (e) {
      await isar.writeTxn(() async {
        await isar.rotaRecords.delete(rota.id);
      });
      state = state.copyWith(statusMessage: '');
      rethrow;
    }

    final ordered = orderParadasByManifestSequence(paradas);
    final pkgTotal = RouteDeliveryStats.totalPackages(ordered);
    rota
      ..pacotesImportados = pkgTotal
      ..paradasImportadas = RouteDeliveryStats.totalStops(ordered);
    final fileLabel = rota.arquivoPlanilhaImportada ?? '';
    state = state.copyWith(
      statusMessage: 'Salvando $pkgTotal pacotes · ${RouteDeliveryStats.totalStops(ordered)} paradas…',
    );
    await isar.writeTxn(() async {
      await isar.paradas.putAll(ordered);
      await isar.rotaRecords.put(rota);
    });
    await RomaneioImportRegistry.registerFile(rota.id, bytes);
    await _removeOlderRoutesSameSpreadsheet(
      isar,
      fileLabel: fileLabel,
      keepRotaId: rota.id,
    );

    state = state.copyWith(
      rotaId: rota.id,
      rota: rota,
      paradas: ordered,
      routePoints: const [],
      navigationLegPoints: const [],
      statusMessage: 'Rota pronta — $pkgTotal pacotes · ${rota.paradasImportadas} paradas',
      pacotesEscaneados: 0,
    );
    unawaited(stripRouteTraceUnlessProOptimized());
    unawaited(_purgeEmptyDraftRoutes(isar, keepRotaId: rota.id));
    unawaited(MapTilePrefetch.prefetchForRoute(paradas: ordered, maxZoom: 15));
    unawaited(fillMissingGeocodesForCurrentRoute());
    return rota.id;
  }

  Future<int> _mergeImportIntoCurrentRota() async {
    final isar = await IsarService.instance;
    final rotaId = state.rotaId!;
    final rota = state.rota!;
    final bytes = await resolveExcelBytes();
    if (bytes == null) {
      throw StateError('Arquivo do romaneio não encontrado. Selecione o PDF/planilha de novo.');
    }

    state = state.copyWith(
      statusMessage: 'Acrescentando entregas à rota…',
      pendingMergeImport: false,
    );

    try {
      if (await RomaneioImportRegistry.containsFile(rotaId, bytes)) {
        throw StateError(RomaneioImportRegistry.duplicateFileMessage);
      }

      final proUnlimited = await _ensureProEntitlementsLoaded();

      state = state.copyWith(statusMessage: 'Lendo romaneio…');
      final parsed = await _import.buildParadas(
        rotaId: rotaId,
        bytes: bytes,
        fileName: state.importFileName,
        geocode: false,
      );
      var incoming = parsed.paradas;
      if (incoming.isNotEmpty &&
          countNewParadasForMerge(state.paradas, incoming) == 0) {
        throw StateError(RomaneioImportRegistry.duplicatePackagesMessage);
      }

      state = state.copyWith(statusMessage: 'Localizando endereços no mapa…');
      await _import.geocodeParadas(
        incoming,
        onProgress: (p) {
          final suffix = p.total > 0 && p.done >= 0 ? ' (${p.done}/${p.total})' : '';
          state = state.copyWith(statusMessage: '${p.message}$suffix');
        },
      );

      if (!proUnlimited &&
          !PlanLimits.withinFreeRouteLimit(state.paradas.length + incoming.length)) {
        throw StateError(
          PlanLimits.importOverLimitMessage(state.paradas.length + incoming.length),
        );
      }

      final beforeMerge = state.paradas.length;
      final combined = mergeRouteParadas(state.paradas, incoming);
      final addedUnique = combined.length - beforeMerge;
      final skippedDupes = state.paradas.length + incoming.length - combined.length;

      if (incoming.isNotEmpty && addedUnique == 0) {
        throw StateError(RomaneioImportRegistry.duplicatePackagesMessage);
      }

      rota
        ..pacotesImportados = RouteDeliveryStats.totalPackages(combined)
        ..paradasImportadas = RouteDeliveryStats.totalStops(combined);

      await isar.writeTxn(() async {
        await isar.paradas.putAll(combined);
        await isar.rotaRecords.put(rota);
      });
      await RomaneioImportRegistry.registerFile(rotaId, bytes);

      state = state.copyWith(
        rota: rota,
        paradas: combined,
        routePoints: const [],
        navigationLegPoints: const [],
        statusMessage: skippedDupes > 0
            ? 'Rota atualizada — +$addedUnique pacotes ($skippedDupes já estavam na rota) · '
                'total ${rota.pacotesImportados} pacotes · ${rota.paradasImportadas} paradas'
            : 'Rota atualizada — +$addedUnique pacotes · total ${rota.pacotesImportados} pacotes · '
                '${rota.paradasImportadas} paradas',
        excelBytes: null,
        pendingImportCachePath: null,
      );
      unawaited(MapTilePrefetch.prefetchForRoute(paradas: combined, maxZoom: 15));
      unawaited(fillMissingGeocodesForCurrentRoute());
      return rotaId;
    } catch (e) {
      state = state.copyWith(statusMessage: '');
      rethrow;
    }
  }

  /// Grátis: ordem crescente do romaneio (Sequence), sem OSRM.
  Future<void> applySpreadsheetOrderOnly({bool force = false}) async {
    final rota = state.rota;
    if (rota == null) return;
    if (!force && paradasMatchManifestOrder(state.paradas)) return;
    rota
      ..otimizada = false
      ..rotaGeometriaJson = null
      ..duracaoMinutos = 0
      ..distanciaKm = 0;

    final ordered = orderParadasByManifestSequence(state.paradas);
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.paradas.putAll(ordered);
      await isar.rotaRecords.put(rota);
    });
    _lastLegOrigin = null;
    state = state.copyWith(
      rota: rota,
      paradas: ordered,
      routePoints: const [],
      navigationLegPoints: const [],
      clearNavigationTarget: true,
    );
  }

  Future<void> optimizeRoute({required bool isPro}) async {
    if (!isPro) {
      throw StateError('Otimização disponível apenas no plano PRO');
    }
    LatLng? driver = state.driverPosition;
    if (state.useGpsOrigin) {
      driver ??= await _location.getCurrentLatLng();
      state = state.copyWith(
        driverPosition: driver ?? state.driverPosition,
        statusMessage: driver == null
            ? 'GPS indisponível — otimizando sem origem'
            : 'Começando a partir do seu local…',
        optimizeProgress: 0.02,
      );
    } else {
      state = state.copyWith(
        statusMessage: 'Preparando otimização…',
        optimizeProgress: 0.02,
      );
    }

    var startFromDriver = state.useGpsOrigin ? driver : null;
    if (startFromDriver != null &&
        !_driverOriginPlausibleForStops(startFromDriver, state.paradas)) {
      startFromDriver = null;
      state = state.copyWith(
        statusMessage:
            'GPS longe das entregas (ex.: emulador) — otimizando só pelas paradas…',
        optimizeProgress: 0.05,
      );
    }

    Future<OsrmOptimizationResult> runOptimize(LatLng? fromDriver) {
      return _osrm.optimizeRoute(
        state.paradas,
        startFromDriver: fromDriver,
        onProgress: (step, total, message) {
          final frac = total > 0 ? (step / total).clamp(0.05, 0.98) : 0.1;
          state = state.copyWith(
            statusMessage: optimizeStatusForUser(message, step, total),
            optimizeProgress: frac,
          );
        },
      );
    }

    OsrmOptimizationResult result;
    try {
      result = await runOptimize(startFromDriver);
    } catch (_) {
      if (startFromDriver == null) rethrow;
      state = state.copyWith(
        statusMessage: 'Tentando de novo sem GPS…',
        optimizeProgress: 0.08,
      );
      result = await runOptimize(null);
    }

    final isar = await IsarService.instance;

    // Preserva paradas que não entraram na ordenação (sem coordenadas).
    final orderedIds = result.orderedStops.map((p) => p.id).toSet();
    final extras = state.paradas.where((p) => !orderedIds.contains(p.id)).toList();

    var finalOrder = [...result.orderedStops, ...extras];
    for (var i = 0; i < finalOrder.length; i++) {
      finalOrder[i].ordemExibicao = i + 1;
    }
    finalOrder = clusterParadasByStopInRouteOrder(finalOrder);

    final rota = state.rota;
    if (rota != null) {
      LatLng? origin = driver;
      if (origin == null) {
        for (final p in finalOrder) {
          if (p.latitude != null && p.longitude != null) {
            origin = LatLng(p.latitude!, p.longitude!);
            break;
          }
        }
      }
      var displayPoints = result.routePoints;
      if (origin != null) {
        rota
          ..origemLatitude = origin.latitude
          ..origemLongitude = origin.longitude;
        displayPoints = routePointsForDisplay(displayPoints, rota);
      }
      rota
        ..otimizada = true
        ..duracaoMinutos = result.durationMinutes
        ..distanciaKm = result.distanceKm
        ..rotaGeometriaJson = jsonEncode(
          displayPoints.map((p) => [p.latitude, p.longitude]).toList(),
        );
      await isar.writeTxn(() async {
        await isar.paradas.putAll(finalOrder);
        await isar.rotaRecords.put(rota);
      });
    }

    var routePts = result.routePoints;
    if (rota != null && rota.origemLatitude != null) {
      routePts = routePointsForDisplay(routePts, rota);
    }

    state = state.copyWith(
      paradas: finalOrder,
      rota: rota,
      routePoints: routePts,
      driverPosition: driver ?? state.driverPosition,
      statusMessage: '',
      optimizeProgress: 0,
    );
  }

  Future<void> confirmRoute() async {
    final isar = await IsarService.instance;
    final rota = state.rota;
    if (rota == null) return;
    rota.status = RotaStatus.ativa;
    final started = DateTime.now();
    await isar.writeTxn(() async {
      await isar.rotaRecords.put(rota);
    });
    await stripRouteTraceUnlessProOptimized();
    state = state.copyWith(
      rota: state.rota ?? rota,
      routeActiveSince: started,
    );
  }

  /// Grátis: sem traçado. PRO/Trial: limpa rota completa se não otimizou; trecho até pin segue PRO.
  Future<void> stripRouteTraceUnlessProOptimized() async {
    if (_showOptimizedRoutePolyline) return;
    _lastLegOrigin = null;
    final rota = state.rota;
    if (rota != null && !_isPro) {
      rota
        ..otimizada = false
        ..rotaGeometriaJson = null;
      final isar = await IsarService.instance;
      await isar.writeTxn(() async {
        await isar.rotaRecords.put(rota);
      });
    }
    state = state.copyWith(
      rota: rota,
      routePoints: _showOptimizedRoutePolyline ? state.routePoints : const [],
      navigationLegPoints: _isProEntitled ? state.navigationLegPoints : const [],
    );
  }

  Future<Parada?> addParadaManual({
    required String address,
    String? trackingCode,
    int? orderSequence,
    String? zipcode,
    bool? entregaComercial,
    String? geocodeCityHint,
    String? neighborhood,
    ManualGeocodeInput? geocodeInput,
  }) async {
    if (state.rotaId == null) {
      await ensureEmptyDraftRota();
    }
    final rotaId = state.rotaId;
    if (rotaId == null) return null;
    if (!_isPro && state.paradas.length >= PlanLimits.freeMaxDeliveriesPerRoute) {
      state = state.copyWith(
        statusMessage: PlanLimits.manualAddBlockedMessage(state.paradas.length),
      );
      return null;
    }

    state = state.copyWith(statusMessage: 'Localizando endereço…');
    final isar = await IsarService.instance;
    final cityForGeocode = geocodeCityHint?.trim().isNotEmpty == true
        ? geocodeCityHint!.trim()
        : inferCityFromAddress(address);
    final manualInput = geocodeInput ??
        ManualGeocodeInput(
          freeform: address,
          city: cityForGeocode.split('/').first.trim(),
          stateUf: cityForGeocode.contains('/')
              ? cityForGeocode.split('/').last.trim()
              : null,
          postalCode: zipcode,
          neighborhood: neighborhood,
        );
    final g = await _geocode.geocodeManualStop(manualInput);
    if (!g.found) {
      state = state.copyWith(
        statusMessage:
            'Não localizamos esse endereço no mapa. Confira rua, número, bairro e cidade.',
      );
      return null;
    }
    final cityMatch = RegExp(r',\s*([^,]+)\s*/\s*([A-Z]{2})\s*,?\s*\d{5}-?\d{3}?\s*$')
        .firstMatch(address);
    final cityFromCep = cityMatch?.group(1)?.trim();
    final cityLabel = (cityFromCep != null && cityFromCep.isNotEmpty)
        ? cityFromCep
        : (geocodeCityHint?.trim().isNotEmpty == true
            ? geocodeCityHint!.trim().split(',').first.trim()
            : inferCityFromAddress(address));
    final n = state.paradas.length + 1;
    final seq = orderSequence != null && orderSequence > 0 ? orderSequence : 0;
    final parada = Parada()
      ..rotaId = rotaId
      ..spxTn = trackingCode ?? ''
      ..destinationAddress = address
      ..zipcode = zipcode?.replaceAll(RegExp(r'\D'), '') ?? ''
      ..city = cityLabel
      ..bairro = neighborhood?.trim() ?? ''
      ..latitude = g.lat
      ..longitude = g.lng
      ..rawLine = trackingCode != null ? '-; -; $trackingCode; $address;' : address
      ..ordemExibicao = n
      ..sequence = seq
      ..stop = seq > 0 ? seq : n
      ..entregaComercial = entregaComercial ?? false
      ..romaneioLayout = state.rota?.romaneioLayout ?? ImportRomaneioLayout.padrao;
    if (entregaComercial == null) {
      parada.entregaComercial = isBusinessDelivery(parada);
    }

    await isar.writeTxn(() async {
      await isar.paradas.put(parada);
    });

    state = state.copyWith(
      paradas: [...state.paradas, parada],
      statusMessage: '',
    );
    return parada;
  }

  Future<Parada?> updateParadaManual({
    required int paradaId,
    required String address,
    String? trackingCode,
    int? orderSequence,
    String? zipcode,
    bool? entregaComercial,
    String? geocodeCityHint,
    String? neighborhood,
    ManualGeocodeInput? geocodeInput,
  }) async {
    final idx = state.paradas.indexWhere((p) => p.id == paradaId);
    if (idx < 0) return null;

    state = state.copyWith(statusMessage: 'Atualizando endereço no mapa…');
    final isar = await IsarService.instance;
    final cityForGeocode = geocodeCityHint?.trim().isNotEmpty == true
        ? geocodeCityHint!.trim()
        : inferCityFromAddress(address);
    final manualInput = geocodeInput ??
        ManualGeocodeInput(
          freeform: address,
          city: cityForGeocode.split('/').first.trim(),
          stateUf: cityForGeocode.contains('/')
              ? cityForGeocode.split('/').last.trim()
              : null,
          postalCode: zipcode,
          neighborhood: neighborhood,
        );
    final g = await _geocode.geocodeManualStop(manualInput);
    if (!g.found) {
      state = state.copyWith(
        statusMessage:
            'Não localizamos esse endereço. Confira rua, número, bairro e cidade.',
      );
      return null;
    }

    final parada = state.paradas[idx];
    final cityMatch = RegExp(r',\s*([^,]+)\s*/\s*([A-Z]{2})\s*,?\s*\d{5}-?\d{3}?\s*$')
        .firstMatch(address);
    final cityFromCep = cityMatch?.group(1)?.trim();
    final cityLabel = (cityFromCep != null && cityFromCep.isNotEmpty)
        ? cityFromCep
        : (geocodeCityHint?.trim().isNotEmpty == true
            ? geocodeCityHint!.trim().split(',').first.trim()
            : inferCityFromAddress(address));

    parada
      ..destinationAddress = address
      ..latitude = g.lat
      ..longitude = g.lng
      ..city = cityLabel;
    if (neighborhood != null && neighborhood.trim().isNotEmpty) {
      parada.bairro = neighborhood.trim();
    }
    if (zipcode != null) {
      parada.zipcode = zipcode.replaceAll(RegExp(r'\D'), '');
    }
    if (trackingCode != null) {
      parada.spxTn = trackingCode;
      parada.rawLine = trackingCode.isEmpty
          ? address
          : '-; -; $trackingCode; $address;';
    }
    if (orderSequence != null && orderSequence > 0) {
      parada.sequence = orderSequence;
      parada.stop = orderSequence;
    }
    if (entregaComercial != null) {
      parada.entregaComercial = entregaComercial;
    } else {
      parada.entregaComercial = isBusinessDelivery(parada);
    }

    var rota = state.rota;
    var routePoints = state.routePoints;
    var clearedOpt = false;
    if (rota?.otimizada == true) {
      rota!
        ..otimizada = false
        ..rotaGeometriaJson = null;
      routePoints = const [];
      clearedOpt = true;
    }

    await isar.writeTxn(() async {
      await isar.paradas.put(parada);
      if (clearedOpt && rota != null) {
        await isar.rotaRecords.put(rota);
      }
    });

    final updated = [...state.paradas];
    _lastLegOrigin = null;
    state = state.copyWith(
      paradas: updated,
      rota: rota,
      routePoints: routePoints,
      navigationLegPoints: const [],
      statusMessage: '',
    );

    if (state.navigationTargetParadaId == paradaId) {
      await refreshNavigationLegForActiveTarget(force: true);
    }
    return parada;
  }

  Future<Parada?> addParadaFromQr(String spx, String endereco) async {
    if (state.rotaId == null) {
      await ensureEmptyDraftRota();
    }
    final isar = await IsarService.instance;
    final rotaId = state.rotaId;
    if (rotaId == null) return null;

    state = state.copyWith(statusMessage: 'Localizando endereço…');
    final g = await _geocode.geocode(
      endereco,
      allowFallback: false,
      cityHint: inferCityFromAddress(endereco),
    );
    final cityField = inferCityFromAddress(endereco);
    final parada = Parada()
      ..rotaId = rotaId
      ..spxTn = spx
      ..destinationAddress = endereco
      ..city = cityField
      ..latitude = g.found ? g.lat : null
      ..longitude = g.found ? g.lng : null
      ..rawLine = '-; -; $spx; $endereco;'
      ..ordemExibicao = state.paradas.length + 1
      ..sequence = state.paradas.length + 1
      ..stop = state.paradas.length + 1
      ..romaneioLayout = state.rota?.romaneioLayout ?? ImportRomaneioLayout.padrao;

    await isar.writeTxn(() async {
      await isar.paradas.put(parada);
    });

    state = state.copyWith(
      paradas: [...state.paradas, parada],
      pacotesEscaneados: state.pacotesEscaneados + 1,
      statusMessage: '',
    );
    return parada;
  }

  Future<String?> findAddressForSpx(String spx) async {
    final isar = await IsarService.instance;
    final all = await isar.paradas.filter().spxTnEqualTo(spx).findAll();
    if (all.isEmpty) return null;
    return all.first.destinationAddress;
  }

  /// Próxima pendente: ordem da rota ou, se [preferNearest], a mais próxima do GPS.
  static Parada? nextPendingParada(
    List<Parada> paradas, {
    LatLng? from,
    bool preferNearest = false,
  }) {
    final pending = paradas.where((p) => !p.entregue && !p.falha).toList();
    if (pending.isEmpty) return null;

    final sameStopPriority = incompleteSameStopPendingPackage(paradas);
    if (sameStopPriority != null) return sameStopPriority;

    pending.sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
    if (preferNearest && from != null) {
      return nearestPendingParada(pending, from) ?? pending.first;
    }
    return pending.first;
  }

  Parada? paradaById(int id) {
    for (final p in state.paradas) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Parada em foco na entrega ativa (alvo manual ou mais próxima).
  Parada? activeNavigationParada() {
    return activeNavigationParadaFrom(state, isPro: _isPro);
  }

  static Parada? activeNavigationParadaFrom(RotaState state, {required bool isPro}) {
    final paradas = state.paradas;
    final id = state.navigationTargetParadaId;
    if (id != null) {
      for (final p in paradas) {
        if (p.id == id && !p.entregue && !p.falha) return p;
      }
    }
    final nearest = useNearestNavigation(state, isPro: isPro);
    return nextPendingParada(
      paradas,
      from: state.driverPosition,
      preferNearest: nearest && state.driverPosition != null,
    );
  }

  LatLng? _navigationOrigin({Parada? afterParada}) {
    if (state.driverPosition != null) return state.driverPosition;
    final fromStop = afterParada ?? paradaById(state.navigationTargetParadaId ?? -1);
    return fromStop != null ? latLngForParada(fromStop) : null;
  }

  /// Só o trecho até o alvo (OSRM). Trechos já percorridos / outros alvos não são desenhados.
  bool _isLongStraightLeg(List<LatLng> leg, {double maxMeters = 150}) {
    if (leg.length != 2) return false;
    return _distance.as(LengthUnit.Meter, leg.first, leg.last) > maxMeters;
  }

  /// Trecho laranja: só condução GPS → parada alvo (OSRM). Não desenha a rota otimizada inteira.
  Future<List<LatLng>> _legFromTo(LatLng from, LatLng to) async {
    final osrm = await _osrm.fetchDrivingLeg(from, to);
    if (osrm.length >= 3) return osrm;
    if (osrm.length >= 2 && !_isLongStraightLeg(osrm)) return osrm;
    return const [];
  }

  Future<void> _drawLegToParada(Parada target, LatLng from) async {
    final dest = latLngForParada(target);
    if (dest == null) {
      state = state.copyWith(
        navigationTargetParadaId: target.id,
        navigationLegPoints: const [],
      );
      return;
    }

    if (!_showNavigationLeg) {
      _lastLegOrigin = null;
      state = state.copyWith(
        navigationTargetParadaId: target.id,
        navigationLegPoints: const [],
      );
      return;
    }

    final targetId = target.id;
    state = state.copyWith(navigationTargetParadaId: targetId);

    final leg = await _legFromTo(from, dest);
    if (state.navigationTargetParadaId != targetId) return;
    _lastLegOrigin = from;
    state = state.copyWith(
      navigationTargetParadaId: targetId,
      navigationLegPoints: leg,
    );
  }

  /// Recalcula o trecho laranja (GPS → parada alvo), automático ou pin manual.
  Future<void> refreshNavigationLegForActiveTarget({bool force = false}) async {
    if (!_showNavigationLeg) {
      if (state.navigationLegPoints.isNotEmpty) {
        state = state.copyWith(navigationLegPoints: const []);
      }
      return;
    }
    final target = activeNavigationParada();
    if (target == null) return;
    final from = _navigationOrigin(afterParada: null);
    if (from == null) return;

    final leg = state.navigationLegPoints;
    final offRoute = leg.length >= 2 &&
        minDistancePointToPolylineMeters(from, leg) > _legOffRouteMeters;
    if (!force &&
        !offRoute &&
        _lastLegOrigin != null &&
        _distance.as(LengthUnit.Meter, _lastLegOrigin!, from) <
            _legRefreshMinMoveMeters) {
      return;
    }
    await _drawLegToParada(target, from);
  }

  /// Define o alvo: mais próximo (GPS) ou parada escolhida no mapa.
  /// O trecho laranja é atualizado em [refreshNavigationLegForActiveTarget].
  Future<void> syncActiveNavigationTarget({
    int? manualParadaId,
    bool preserveLockedTarget = false,
  }) async {
    final paradas = state.paradas;
    Parada? target;
    final origin = _navigationOrigin(afterParada: null);

    if (manualParadaId != null) {
      target = paradaById(manualParadaId);
      if (target != null && (target.entregue || target.falha)) target = null;
    } else {
      if (preserveLockedTarget) {
        final id = state.navigationTargetParadaId;
        if (id != null) {
          target = paradaById(id);
          if (target != null && (target.entregue || target.falha)) target = null;
        }
      }
      target ??= nextPendingParada(
        paradas,
        from: origin,
        preferNearest: _useNearestNavigation && origin != null,
      );
    }

    if (target == null) {
      _lastLegOrigin = null;
      state = state.copyWith(
        clearNavigationTarget: true,
        navigationLegPoints: const [],
      );
      return;
    }

    final prevId = state.navigationTargetParadaId;
    if (prevId != target.id) {
      _lastLegOrigin = null;
      state = state.copyWith(
        navigationTargetParadaId: target.id,
        navigationLegPoints: const [],
      );
    } else {
      state = state.copyWith(navigationTargetParadaId: target.id);
    }
  }

  Future<void> selectNavigationTarget(
    int paradaId, {
    bool awaitLegRefresh = true,
  }) async {
    _lastLegOrigin = null;
    state = state.copyWith(navigationLegPoints: const []);
    await syncActiveNavigationTarget(manualParadaId: paradaId);
    final leg = refreshNavigationLegForActiveTarget(force: true);
    if (awaitLegRefresh) {
      await leg;
    } else {
      unawaited(leg);
    }
  }

  /// Próximo alvo (setas): mesmo endereço; PRO otimizado → mais próximo; senão ordem da rota.
  static Parada? nextForDeliveryNavigation(
    RotaState state,
    Parada current, {
    required bool isPro,
  }) {
    final paradas = state.paradas;
    final siblings = pendingSiblingsAtSameStop(paradas, current);
    if (siblings.isNotEmpty) return siblings.first;

    if (useNearestNavigation(state, isPro: isPro)) {
      final from = state.driverPosition ?? latLngForParada(current);
      if (from != null) {
        final near = nearestPendingParada(paradas, from);
        if (near != null && near.id != current.id) return near;
      }
    }
    return skipToNextStopInRoute(paradas, current) ??
        nextDeliveryTarget(paradas, current);
  }

  /// Próxima parada pendente na ordem da rota após [current] (botão Próxima no mapa).
  static Parada? nextPendingInRouteOrderAfter(List<Parada> paradas, Parada current) {
    Parada? candidate;
    for (final p in paradas) {
      if (p.ordemExibicao <= current.ordemExibicao) continue;
      if (p.entregue || p.falha) continue;
      if (candidate == null || p.ordemExibicao < candidate.ordemExibicao) {
        candidate = p;
      }
    }
    return candidate;
  }

  /// Próxima parada na ordem da rota (como botão "Próxima" do Circuit).
  static Parada? nextInRouteOrder(List<Parada> paradas, Parada current) {
    Parada? candidate;
    for (final p in paradas) {
      if (p.ordemExibicao <= current.ordemExibicao) continue;
      if (candidate == null || p.ordemExibicao < candidate.ordemExibicao) {
        candidate = p;
      }
    }
    return candidate;
  }

  static Parada? previousInRouteOrder(List<Parada> paradas, Parada current) {
    Parada? candidate;
    for (final p in paradas) {
      if (p.ordemExibicao >= current.ordemExibicao) continue;
      if (candidate == null || p.ordemExibicao > candidate.ordemExibicao) {
        candidate = p;
      }
    }
    return candidate;
  }

  Future<void> revertParadaDelivery(int paradaId) async {
    final idx = state.paradas.indexWhere((p) => p.id == paradaId);
    if (idx < 0) return;
    final parada = state.paradas[idx];
    parada.entregue = false;
    parada.falha = false;
    final updated = [...state.paradas];
    state = state.copyWith(paradas: updated);
    _lastLegOrigin = null;
    state = state.copyWith(navigationLegPoints: const []);

    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.paradas.put(parada);
    });

    final from = state.driverPosition ?? latLngForParada(parada);
    if (from != null) {
      await _drawLegToParada(parada, from);
    } else {
      state = state.copyWith(navigationTargetParadaId: parada.id);
    }
  }

  /// Marca entrega/falha. Próximo = mesmo Stop (outro pacote) ou ordem da rota.
  Future<Parada?> markEntregue(int paradaId, {required bool entregue, bool falha = false}) async {
    final idx = state.paradas.indexWhere((p) => p.id == paradaId);
    if (idx < 0) return null;
    final parada = state.paradas[idx];
    parada.entregue = entregue;
    parada.falha = falha;
    final updated = [...state.paradas];
    state = state.copyWith(paradas: updated);

    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.paradas.put(parada);
    });

    final shouldAdvance = (entregue && !falha) || falha;
    if (!shouldAdvance) return null;

    _lastLegOrigin = null;
    state = state.copyWith(
      clearNavigationTarget: true,
      navigationLegPoints: const [],
    );

    final from = state.driverPosition ?? latLngForParada(parada);
    Parada? next;
    final siblings = pendingSiblingsAtSameStop(updated, parada);
    if (siblings.isNotEmpty) {
      next = siblings.first;
    } else if (_useNearestNavigation && from != null) {
      next = nextPendingParada(
        updated,
        from: from,
        preferNearest: true,
      );
    } else {
      next = nextDeliveryTarget(updated, parada);
    }
    next ??= nextPendingParada(updated);
    if (next == null) {
      state = state.copyWith(clearNavigationTarget: true, navigationLegPoints: const []);
      return null;
    }

    if (from == null) {
      state = state.copyWith(navigationTargetParadaId: next.id);
      return next;
    }

    await _drawLegToParada(next, from);
    return next;
  }

  Future<void> updateRouteFinanceBasics({
    double? kmInicial,
    double? valorPago,
  }) async {
    final rota = state.rota;
    if (rota == null) return;
    if (kmInicial != null) rota.kmInicial = kmInicial;
    if (valorPago != null) rota.valorPago = valorPago;
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.rotaRecords.put(rota);
    });
    state = state.copyWith(rota: rota);
  }

  Future<void> removeGasto(int gastoId) async {
    final isar = await IsarService.instance;
    await isar.writeTxn(() async {
      await isar.gastos.delete(gastoId);
    });
    state = state.copyWith(
      gastos: state.gastos.where((g) => g.id != gastoId).toList(),
    );
  }

  Future<void> addGasto(String tipo, double valor, {String? fotoPath}) async {
    final rotaId = state.rotaId;
    if (rotaId == null) return;
    final isar = await IsarService.instance;
    final gasto = Gasto()
      ..rotaId = rotaId
      ..tipo = tipo
      ..valor = valor
      ..fotoPath = fotoPath;
    await isar.writeTxn(() async {
      await isar.gastos.put(gasto);
    });
    state = state.copyWith(gastos: [...state.gastos, gasto]);
  }

  Future<void> finalizeRoute({required double kmFinal}) async {
    await DeliveryCockpitService.instance.stop();
    final isar = await IsarService.instance;
    final rota = state.rota;
    if (rota == null) return;
    final now = DateTime.now();
    rota
      ..kmFinal = kmFinal
      ..status = RotaStatus.finalizada
      ..finalizadaEm = now
      ..titulo = ensureTituloComData(rota.titulo, now);
    await isar.writeTxn(() async {
      await isar.rotaRecords.put(rota);
    });
    state = state.copyWith(rota: rota);
  }

  void clearWorkingRoute({bool keepCreationMeta = false}) {
    if (!keepCreationMeta) {
      state = const RotaState();
      return;
    }
    state = RotaState(
      pendingRouteScheduledAt: state.pendingRouteScheduledAt,
      pendingRouteLabel: state.pendingRouteLabel,
      pendingImportCachePath: state.pendingImportCachePath,
      selectedColumns: state.selectedColumns,
      useGpsOrigin: state.useGpsOrigin,
    );
  }
}

final rotaProvider = StateNotifierProvider<RotaNotifier, RotaState>((ref) {
  return RotaNotifier(ref);
});


final historicoProvider = FutureProvider((ref) async {
  return ref.read(rotaProvider.notifier).loadHistorico();
});

bool isValidQrCode(String code) => looksLikeTrackingCode(code);
