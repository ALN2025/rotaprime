import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';

/// Ordenação TSP local (vizinho mais próximo + 2-opt) — funciona com qualquer N.
class RouteOptimizer {
  static const _distance = Distance();

  List<Parada> optimize(List<Parada> paradas) {
    final stops = paradas.where((p) => p.latitude != null && p.longitude != null).toList();
    if (stops.length <= 2) return List<Parada>.from(paradas);

    var route = _nearestNeighbor(stops);
    route = _twoOpt(route);

    final withoutCoords =
        paradas.where((p) => p.latitude == null || p.longitude == null).toList();
    return [...route, ...withoutCoords];
  }

  List<Parada> _nearestNeighbor(List<Parada> stops) {
    final remaining = List<Parada>.from(stops);
    final route = <Parada>[remaining.removeAt(0)];
    while (remaining.isNotEmpty) {
      final last = route.last;
      var bestIdx = 0;
      var bestDist = double.infinity;
      for (var i = 0; i < remaining.length; i++) {
        final d = _dist(last, remaining[i]);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      route.add(remaining.removeAt(bestIdx));
    }
    return route;
  }

  List<Parada> _twoOpt(List<Parada> route) {
    if (route.length < 4) return route;
    var improved = true;
    var best = List<Parada>.from(route);
    while (improved) {
      improved = false;
      for (var i = 0; i < best.length - 2; i++) {
        for (var k = i + 1; k < best.length - 1; k++) {
          final delta = _twoOptDelta(best, i, k);
          if (delta < -1e-6) {
            best = _reverseSegment(best, i + 1, k);
            improved = true;
          }
        }
      }
    }
    return best;
  }

  double _twoOptDelta(List<Parada> route, int i, int k) {
    final a = route[i];
    final b = route[i + 1];
    final c = route[k];
    final d = route[k + 1];
    final before = _dist(a, b) + _dist(c, d);
    final after = _dist(a, c) + _dist(b, d);
    return after - before;
  }

  List<Parada> _reverseSegment(List<Parada> route, int start, int end) {
    final copy = List<Parada>.from(route);
    while (start < end) {
      final tmp = copy[start];
      copy[start] = copy[end];
      copy[end] = tmp;
      start++;
      end--;
    }
    return copy;
  }

  double _dist(Parada a, Parada b) {
    return _distance.as(
      LengthUnit.Meter,
      LatLng(a.latitude!, a.longitude!),
      LatLng(b.latitude!, b.longitude!),
    );
  }

  double totalMeters(List<Parada> route) {
    var sum = 0.0;
    for (var i = 0; i < route.length - 1; i++) {
      if (route[i].latitude == null || route[i + 1].latitude == null) continue;
      sum += _dist(route[i], route[i + 1]);
    }
    return sum;
  }

  int estimateMinutes(List<Parada> route, {double avgKmh = 35}) {
    final km = totalMeters(route) / 1000;
    return math.max(1, (km / avgKmh * 60).round());
  }
}
