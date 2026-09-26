import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';

class OsrmOptimizationResult {
  OsrmOptimizationResult({
    required this.orderedStops,
    required this.durationMinutes,
    required this.distanceKm,
    required this.routePoints,
  });

  final List<Parada> orderedStops;
  final int durationMinutes;
  final double distanceKm;
  final List<LatLng> routePoints;
}

typedef OptimizeProgressCallback = void Function(int step, int total, String message);

class OsrmException implements Exception {
  OsrmException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Otimização 100% via OSRM público gratuito (router.project-osrm.org),
/// com blocos automáticos para qualquer quantidade de paradas.
class OsrmService {
  static const _base = 'https://router.project-osrm.org';

  /// Limites conservadores da instância free (URL + tempo de resposta).
  static const _tripMax = 70;
  /// Mais pontos por trecho = menos idas ao servidor (importante em 4G).
  static const _routeMax = 45;
  static const _tableMax = 70;
  static const _minGapMs = 280;
  static const _maxRetries = 4;

  final http.Client _http = http.Client();
  DateTime _lastCall = DateTime.fromMillisecondsSinceEpoch(0);

  Future<OsrmOptimizationResult> optimizeRoute(
    List<Parada> paradas, {
    LatLng? startFromDriver,
    OptimizeProgressCallback? onProgress,
  }) async {
    final withCoords = paradas
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
    final withoutCoords =
        paradas.where((p) => p.latitude == null || p.longitude == null).toList();

    if (withCoords.length < 2) {
      final ordered = [...withCoords, ...withoutCoords];
      final pts = withCoords.map((p) => LatLng(p.latitude!, p.longitude!)).toList();
      return OsrmOptimizationResult(
        orderedStops: ordered,
        durationMinutes: 1,
        distanceKm: 0,
        routePoints: pts,
      );
    }

    var step = 0;
    final orderSteps = _estimateOrderSteps(withCoords.length);
    final routeSteps = _estimateRouteSteps(withCoords.length);
    final totalSteps = orderSteps + routeSteps;

    void progress(String msg) {
      step = math.min(step + 1, totalSteps);
      onProgress?.call(step, totalSteps, msg);
    }

    progress('OSRM: ordenando ${withCoords.length} paradas…');
    final orderedCoords = startFromDriver != null
        ? await _optimizeOrderFromDriver(startFromDriver, withCoords, progress)
        : await _optimizeOrderOsrm(withCoords, progress);

    progress('OSRM: calculando trajeto (${orderedCoords.length} pontos)…');
    final geometryOrigin = startFromDriver ??
        (orderedCoords.isNotEmpty
            ? LatLng(orderedCoords.first.latitude!, orderedCoords.first.longitude!)
            : null);
    final metrics = geometryOrigin != null
        ? await _fetchRouteGeometryFromDriver(geometryOrigin, orderedCoords, progress)
        : await _fetchRouteGeometryOsrm(orderedCoords, progress);

    return OsrmOptimizationResult(
      orderedStops: [...orderedCoords, ...withoutCoords],
      durationMinutes: metrics.durationMinutes,
      distanceKm: metrics.distanceKm,
      routePoints: metrics.points,
    );
  }

  int _estimateOrderSteps(int n) {
    if (n <= _tripMax) return 1;
    final chunks = (n / _tripMax).ceil();
    return chunks + _estimateOrderSteps(chunks);
  }

  int _estimateRouteSteps(int n) {
    if (n <= _routeMax) return 1;
    return (n / (_routeMax - 1)).ceil();
  }

  Future<List<Parada>> _optimizeOrderFromDriver(
    LatLng driver,
    List<Parada> stops,
    void Function(String msg) progress,
  ) async {
    if (stops.isEmpty) return stops;
    if (stops.length + 1 <= _tripMax) {
      final ordered = await _tryOsrmTripFromDriver(driver, stops);
      if (ordered != null) return ordered;
    }
    progress('OSRM: ordenando a partir do GPS…');
    final nearest = await _nearestStopFromDriver(driver, stops);
    final rotated = [...stops.sublist(nearest), ...stops.sublist(0, nearest)];
    return _optimizeOrderOsrm(rotated, progress);
  }

  Future<int> _nearestStopFromDriver(LatLng driver, List<Parada> stops) async {
    final durations = await _osrmTableDriverToStops(driver, stops);
    if (durations == null || durations.isEmpty) return 0;
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < durations.length; i++) {
      final d = durations[i];
      if (d != null && d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  Future<List<double?>?> _osrmTableDriverToStops(LatLng driver, List<Parada> stops) async {
    final coordStr =
        '${driver.longitude.toStringAsFixed(6)},${driver.latitude.toStringAsFixed(6)};${_coordsPath(stops)}';
    final dest = List.generate(stops.length, (i) => i + 1).join(';');
    final uri = Uri.parse(
      '$_base/table/v1/driving/$coordStr?sources=0&destinations=$dest&annotations=duration',
    );
    final data = await _getJson(uri);
    if (data == null || data['code'] != 'Ok') return null;
    final durations = data['durations'] as List<dynamic>?;
    if (durations == null || durations.isEmpty) return null;
    final row = durations.first as List<dynamic>;
    return row.map((d) => d == null ? null : (d as num).toDouble()).toList();
  }

  Future<List<Parada>?> _tryOsrmTripFromDriver(LatLng driver, List<Parada> stops) async {
    final coordStr =
        '${driver.longitude.toStringAsFixed(6)},${driver.latitude.toStringAsFixed(6)};${_coordsPath(stops)}';
    final uri = Uri.parse(
      '$_base/trip/v1/driving/$coordStr?source=first&roundtrip=false&geometries=geojson',
    );
    final data = await _getJson(uri);
    if (data == null || data['code'] != 'Ok') return null;
    final waypoints = data['waypoints'] as List<dynamic>?;
    if (waypoints == null || waypoints.length != stops.length + 1) return null;

    final order = List.generate(stops.length + 1, (inputIndex) {
      final wp = waypoints[inputIndex] as Map<String, dynamic>;
      return (
        inputIndex: inputIndex,
        tripIndex: wp['waypoint_index'] as int,
      );
    })
      ..sort((a, b) => a.tripIndex.compareTo(b.tripIndex));

    return order
        .where((e) => e.inputIndex > 0)
        .map((e) => stops[e.inputIndex - 1])
        .toList();
  }

  Future<({List<LatLng> points, int durationMinutes, double distanceKm})>
      _fetchRouteGeometryFromDriver(
    LatLng driver,
    List<Parada> ordered,
    void Function(String msg) progress,
  ) async {
    final ghost = _ghostParada(driver.latitude, driver.longitude);
    return _fetchRouteGeometryOsrm([ghost, ...ordered], progress);
  }

  Parada _ghostParada(double lat, double lng) {
    return Parada()
      ..latitude = lat
      ..longitude = lng
      ..destinationAddress = 'Motorista';
  }

  /// Ordenação hierárquica: trip OSRM em blocos + trip OSRM entre blocos (recursivo).
  Future<List<Parada>> _optimizeOrderOsrm(
    List<Parada> stops,
    void Function(String msg) progress,
  ) async {
    if (stops.length <= 1) return stops;
    if (stops.length <= _tripMax) {
      return _tripWithSplitFallback(stops, progress);
    }

    final rawChunks = _chunkList(stops, _tripMax);
    final optimizedChunks = <List<Parada>>[];
    for (var i = 0; i < rawChunks.length; i++) {
      progress('OSRM trip bloco ${i + 1}/${rawChunks.length} (${rawChunks[i].length} paradas)');
      optimizedChunks.add(await _optimizeOrderOsrm(rawChunks[i], progress));
    }

    if (optimizedChunks.length == 1) return optimizedChunks.first;

    final reps = optimizedChunks.map((c) => c.first).toList();
    progress('OSRM: ordenando ${reps.length} blocos…');
    final chunkOrder = await _tripWithSplitFallback(reps, progress);

    final merged = <Parada>[];
    Parada? previous;
    for (final rep in chunkOrder) {
      final idx = reps.indexWhere((r) => identical(r, rep) || r.id == rep.id);
      if (idx < 0) continue;
      var chunk = List<Parada>.from(optimizedChunks[idx]);
      if (chunk.isEmpty) continue;
      if (previous != null) {
        chunk = await _rotateChunkByOsrmTable(previous, chunk, progress);
      }
      merged.addAll(chunk);
      previous = merged.last;
    }
    return merged;
  }

  /// Trip OSRM; se falhar, divide o bloco ao meio e recombine via tabela OSRM.
  Future<List<Parada>> _tripWithSplitFallback(
    List<Parada> stops,
    void Function(String msg) progress,
  ) async {
    if (stops.length <= 1) return stops;

    final trip = await _osrmTrip(stops);
    if (trip != null) return trip;

    if (stops.length <= 3) {
      progress('OSRM table: permutação curta (${stops.length})');
      return _orderSmallSetByTable(stops);
    }

    progress('OSRM: subdividindo bloco (${stops.length} paradas)…');
    final mid = stops.length ~/ 2;
    final left = await _tripWithSplitFallback(stops.sublist(0, mid), progress);
    final right = await _tripWithSplitFallback(stops.sublist(mid), progress);
    final rotatedRight = await _rotateChunkByOsrmTable(left.last, right, progress);
    return [...left, ...rotatedRight];
  }

  Future<List<Parada>> _orderSmallSetByTable(List<Parada> stops) async {
    if (stops.length <= 1) return stops;
    if (stops.length == 2) return stops;

    var bestOrder = List<Parada>.from(stops);
    var bestCost = double.infinity;

    final indices = List.generate(stops.length, (i) => i);
    _permute(indices, 0, (perm) {
      final order = perm.map((i) => stops[i]).toList();
      // custo estimado por soma haversine — só escolhe permutação; validação final é OSRM route
      var cost = 0.0;
      for (var i = 0; i < order.length - 1; i++) {
        cost += _haversineMeters(order[i], order[i + 1]);
      }
      if (cost < bestCost) {
        bestCost = cost;
        bestOrder = order;
      }
    });

    // Refina com matriz OSRM (apenas para conjuntos pequenos).
    final matrix = await _osrmTableAll(stops);
    if (matrix != null) {
      var bestOsrm = double.infinity;
      var osrmOrder = List<Parada>.from(stops);
      _permute(List.generate(stops.length, (i) => i), 0, (perm) {
        var cost = 0.0;
        for (var i = 0; i < perm.length - 1; i++) {
          cost += matrix[perm[i]][perm[i + 1]];
          if (cost >= bestOsrm) return;
        }
        if (cost < bestOsrm) {
          bestOsrm = cost;
          osrmOrder = perm.map((i) => stops[i]).toList();
        }
      });
      return osrmOrder;
    }
    return bestOrder;
  }

  void _permute(List<int> arr, int start, void Function(List<int> perm) fn) {
    if (start == arr.length - 1) {
      fn(List<int>.from(arr));
      return;
    }
    for (var i = start; i < arr.length; i++) {
      final tmp = arr[start];
      arr[start] = arr[i];
      arr[i] = tmp;
      _permute(arr, start + 1, fn);
      final tmp2 = arr[start];
      arr[start] = arr[i];
      arr[i] = tmp2;
    }
  }

  Future<List<Parada>> _rotateChunkByOsrmTable(
    Parada from,
    List<Parada> chunk,
    void Function(String msg) progress,
  ) async {
    if (chunk.length <= 1) return chunk;
    progress('OSRM table: encaixando bloco (${chunk.length} paradas)');
    final durations = await _osrmTableOneToMany(from, chunk);
    if (durations == null || durations.isEmpty) return chunk;

    var bestIdx = 0;
    var best = double.infinity;
    for (var i = 0; i < durations.length; i++) {
      final d = durations[i];
      if (d != null && d < best) {
        best = d;
        bestIdx = i;
      }
    }
    return [...chunk.sublist(bestIdx), ...chunk.sublist(0, bestIdx)];
  }

  Future<List<Parada>?> _osrmTrip(List<Parada> stops) async {
    if (stops.length < 2) return stops;

    final coordStr = _coordsPath(stops);
    final uri = Uri.parse(
      '$_base/trip/v1/driving/$coordStr?source=first&roundtrip=false&geometries=geojson',
    );

    final data = await _getJson(uri);
    if (data == null || data['code'] != 'Ok') return null;

    final waypoints = data['waypoints'] as List<dynamic>?;
    if (waypoints == null || waypoints.length != stops.length) return null;

    final order = List.generate(stops.length, (inputIndex) {
      final wp = waypoints[inputIndex] as Map<String, dynamic>;
      return (
        inputIndex: inputIndex,
        tripIndex: wp['waypoint_index'] as int,
      );
    })
      ..sort((a, b) => a.tripIndex.compareTo(b.tripIndex));

    return order.map((e) => stops[e.inputIndex]).toList();
  }

  Future<List<double?>?> _osrmTableOneToMany(Parada from, List<Parada> targets) async {
    final all = [from, ...targets];
    if (all.length > _tableMax) {
      // OSRM table free: divide destinos
      final out = <double?>[];
      for (final sub in _chunkList(targets, _tableMax - 1)) {
        final part = await _osrmTableOneToMany(from, sub);
        if (part == null) return null;
        out.addAll(part);
      }
      return out;
    }

    final coordStr = _coordsPath(all);
    final dest = List.generate(targets.length, (i) => i + 1).join(';');
    final uri = Uri.parse(
      '$_base/table/v1/driving/$coordStr?sources=0&destinations=$dest&annotations=duration',
    );
    final data = await _getJson(uri);
    if (data == null || data['code'] != 'Ok') return null;
    final durations = data['durations'] as List<dynamic>?;
    if (durations == null || durations.isEmpty) return null;
    final row = durations.first as List<dynamic>;
    return row.map((d) => d == null ? null : (d as num).toDouble()).toList();
  }

  Future<List<List<double>>?> _osrmTableAll(List<Parada> stops) async {
    if (stops.length > _tableMax) return null;
    final coordStr = _coordsPath(stops);
    final uri = Uri.parse(
      '$_base/table/v1/driving/$coordStr?annotations=duration',
    );
    final data = await _getJson(uri);
    if (data == null || data['code'] != 'Ok') return null;
    final durations = data['durations'] as List<dynamic>?;
    if (durations == null) return null;
    return durations
        .map((row) => (row as List<dynamic>).map((d) => (d as num).toDouble()).toList())
        .toList();
  }

  Future<({List<LatLng> points, int durationMinutes, double distanceKm})> _fetchRouteGeometryOsrm(
    List<Parada> ordered,
    void Function(String msg) progress,
  ) async {
    if (ordered.length < 2) {
      final pts = ordered.map((p) => LatLng(p.latitude!, p.longitude!)).toList();
      return (points: pts, durationMinutes: 1, distanceKm: 0.0);
    }

    final segments = <List<Parada>>[];
    var i = 0;
    while (i < ordered.length) {
      final end = math.min(i + _routeMax, ordered.length);
      var seg = ordered.sublist(i, end);
      if (segments.isNotEmpty && seg.isNotEmpty) {
        seg = [segments.last.last, ...seg];
      }
      segments.add(seg);
      i = end;
      if (end >= ordered.length) break;
    }

    final allPoints = <LatLng>[];
    var totalDuration = 0.0;
    var totalDistance = 0.0;

    const batchSize = 2;
    for (var s = 0; s < segments.length; s += batchSize) {
      final end = math.min(s + batchSize, segments.length);
      progress('OSRM route trecho ${s + 1}-$end/${segments.length}');
      final batch = segments.sublist(s, end);
      final metricsList = await Future.wait(
        batch.map((seg) => _osrmRouteWithSplit(seg, (_) {})),
      );
      for (var j = 0; j < metricsList.length; j++) {
        var pts = metricsList[j].points;
        if (allPoints.isNotEmpty && pts.isNotEmpty) {
          pts = pts.sublist(1);
        }
        allPoints.addAll(pts);
        totalDuration += metricsList[j].durationSeconds;
        totalDistance += metricsList[j].distanceMeters;
      }
    }

    if (allPoints.isEmpty) {
      throw OsrmException('OSRM não retornou geometria da rota.');
    }

    return (
      points: allPoints,
      durationMinutes: (totalDuration / 60).round().clamp(1, 999999),
      distanceKm: totalDistance / 1000,
    );
  }

  Future<({List<LatLng> points, double durationSeconds, double distanceMeters})>
      _osrmRouteWithSplit(
    List<Parada> stops,
    void Function(String msg) progress,
  ) async {
    final direct = await _osrmRoute(stops);
    if (direct != null) return direct;

    if (stops.length <= 2) {
      throw OsrmException('OSRM route falhou para trecho com ${stops.length} pontos.');
    }

    progress('OSRM route: subdividindo trecho (${stops.length} pontos)…');
    final mid = stops.length ~/ 2;
    final a = await _osrmRouteWithSplit(stops.sublist(0, mid + 1), progress);
    final b = await _osrmRouteWithSplit([stops[mid], ...stops.sublist(mid)], progress);
    var ptsB = b.points;
    if (a.points.isNotEmpty && ptsB.isNotEmpty) ptsB = ptsB.sublist(1);
    return (
      points: [...a.points, ...ptsB],
      durationSeconds: a.durationSeconds + b.durationSeconds,
      distanceMeters: a.distanceMeters + b.distanceMeters,
    );
  }

  /// Trajeto de condução entre dois pontos (trecho único no mapa de entrega).
  Future<List<LatLng>> fetchDrivingLeg(LatLng from, LatLng to) async {
    final a = Parada()
      ..latitude = from.latitude
      ..longitude = from.longitude;
    final b = Parada()
      ..latitude = to.latitude
      ..longitude = to.longitude;
    final route = await _osrmRoute([a, b], overview: 'full');
    if (route != null && route.points.length >= 2) {
      return route.points;
    }
    return const [];
  }

  Future<({List<LatLng> points, double durationSeconds, double distanceMeters})?> _osrmRoute(
    List<Parada> stops, {
    String overview = 'simplified',
  }) async {
    if (stops.length < 2) return null;
    final coordStr = _coordsPath(stops);
    final uri = Uri.parse(
      '$_base/route/v1/driving/$coordStr?overview=$overview&geometries=geojson',
    );
    final data = await _getJson(uri);
    if (data == null || data['code'] != 'Ok') return null;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;
    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordsList = geometry['coordinates'] as List<dynamic>;
    final points = coordsList
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    return (
      points: points,
      durationSeconds: (route['duration'] as num).toDouble(),
      distanceMeters: (route['distance'] as num).toDouble(),
    );
  }

  Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      await _throttle();
      try {
        final response = await _http.get(uri).timeout(const Duration(seconds: 45));
        if (response.statusCode == 429 || response.statusCode >= 500) {
          await Future<void>.delayed(Duration(milliseconds: 800 * (attempt + 1)));
          continue;
        }
        if (response.statusCode != 200) return null;
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        await Future<void>.delayed(Duration(milliseconds: 600 * (attempt + 1)));
      }
    }
    return null;
  }

  Future<void> _throttle() async {
    final elapsed = DateTime.now().difference(_lastCall);
    if (elapsed.inMilliseconds < _minGapMs) {
      await Future<void>.delayed(Duration(milliseconds: _minGapMs - elapsed.inMilliseconds));
    }
    _lastCall = DateTime.now();
  }

  String _coordsPath(List<Parada> stops) {
    return stops
        .map((p) => '${p.longitude!.toStringAsFixed(6)},${p.latitude!.toStringAsFixed(6)}')
        .join(';');
  }

  List<List<T>> _chunkList<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += size) {
      chunks.add(items.sublist(i, math.min(i + size, items.length)));
    }
    return chunks;
  }

  double _haversineMeters(Parada a, Parada b) {
    const distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(a.latitude!, a.longitude!),
      LatLng(b.latitude!, b.longitude!),
    );
  }
}
