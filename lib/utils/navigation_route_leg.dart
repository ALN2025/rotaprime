import 'package:latlong2/latlong.dart';

const _distance = Distance();

/// Trecho da rota completa entre [from] e [to], seguindo a geometria otimizada.
/// Se não couber na rota salva, usa [fallback] (ex.: OSRM).
List<LatLng> navigationLegAlongRoute(
  List<LatLng> fullRoute,
  LatLng from,
  LatLng to, {
  List<LatLng>? fallback,
}) {
  if (fullRoute.length < 2) {
    return _fallbackOrLine(fallback, from, to);
  }

  final iFrom = _nearestIndex(fullRoute, from);
  final iTo = _nearestIndex(fullRoute, to);

  if (iFrom == iTo) {
    return _fallbackOrLine(fallback, from, to);
  }

  final List<LatLng> core;
  if (iFrom < iTo) {
    core = fullRoute.sublist(iFrom, iTo + 1).toList();
  } else {
    core = fullRoute.sublist(iTo, iFrom + 1).reversed.toList();
  }

  if (core.length < 2) {
    return _fallbackOrLine(fallback, from, to);
  }

  core[0] = from;
  core[core.length - 1] = to;
  return _dedupeAdjacent(core);
}

List<LatLng> _fallbackOrLine(List<LatLng>? fallback, LatLng from, LatLng to) {
  if (fallback != null && fallback.length >= 2) return fallback;
  return [from, to];
}

int _nearestIndex(List<LatLng> route, LatLng point) {
  var best = 0;
  var bestM = double.infinity;
  for (var i = 0; i < route.length; i++) {
    final m = _distance.as(LengthUnit.Meter, route[i], point);
    if (m < bestM) {
      bestM = m;
      best = i;
    }
  }
  return best;
}

List<LatLng> _dedupeAdjacent(List<LatLng> points) {
  if (points.length < 2) return points;
  final out = <LatLng>[points.first];
  for (var i = 1; i < points.length; i++) {
    if (_distance.as(LengthUnit.Meter, out.last, points[i]) > 3) {
      out.add(points[i]);
    }
  }
  return out.length >= 2 ? out : points;
}

/// Distância mínima (m) de [point] ao polyline — detecta desvio de rua.
double minDistancePointToPolylineMeters(LatLng point, List<LatLng> polyline) {
  if (polyline.isEmpty) return double.infinity;
  if (polyline.length == 1) {
    return _distance.as(LengthUnit.Meter, point, polyline.first);
  }
  var minM = double.infinity;
  for (var i = 0; i < polyline.length - 1; i++) {
    final d = _distanceToSegmentMeters(point, polyline[i], polyline[i + 1]);
    if (d < minM) minM = d;
  }
  return minM;
}

double _distanceToSegmentMeters(LatLng p, LatLng a, LatLng b) {
  final len = _distance.as(LengthUnit.Meter, a, b);
  if (len < 1) return _distance.as(LengthUnit.Meter, p, a);
  final brg = _distance.bearing(a, b);
  var tLow = 0.0;
  var tHigh = 1.0;
  for (var i = 0; i < 12; i++) {
    final t1 = tLow + (tHigh - tLow) / 3;
    final t2 = tHigh - (tHigh - tLow) / 3;
    final q1 = _distance.offset(a, brg, t1 * len);
    final q2 = _distance.offset(a, brg, t2 * len);
    final d1 = _distance.as(LengthUnit.Meter, p, q1);
    final d2 = _distance.as(LengthUnit.Meter, p, q2);
    if (d1 < d2) {
      tHigh = t2;
    } else {
      tLow = t1;
    }
  }
  final mid = (tLow + tHigh) / 2;
  final q = _distance.offset(a, brg, mid * len);
  return _distance.as(LengthUnit.Meter, p, q);
}
