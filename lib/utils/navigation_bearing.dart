import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

const _distance = Distance();

/// Rumo em graus (0 = norte, horário) de [from] até [to].
double bearingDegrees(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLon = (to.longitude - from.longitude) * math.pi / 180;
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  final brng = math.atan2(y, x) * 180 / math.pi;
  return (brng + 360) % 360;
}

/// Diferença angular mínima entre duas direções (0–180°).
double headingDeltaDegrees(double a, double b) {
  var d = (a - b).abs() % 360;
  if (d > 180) d = 360 - d;
  return d;
}

/// True se o GPS aponta claramente contra o destino (> ~100° de erro).
bool isHeadingAgainstTarget({
  required LatLng from,
  required LatLng to,
  required double headingDegrees,
  double minErrorDegrees = 100,
}) {
  if (headingDegrees.isNaN || headingDegrees < 0) return false;
  final bearing = bearingDegrees(from, to);
  return headingDeltaDegrees(headingDegrees, bearing) >= minErrorDegrees;
}

double metersBetween(LatLng a, LatLng b) =>
    _distance.as(LengthUnit.Meter, a, b);

/// Rumo esperado seguindo a polyline à frente do motorista.
double? bearingAlongRouteAhead(
  LatLng from,
  List<LatLng> points, {
  double lookAheadMeters = 40,
}) {
  if (points.length < 2) return null;

  var bestI = 0;
  var bestD = double.infinity;
  for (var i = 0; i < points.length; i++) {
    final d = metersBetween(from, points[i]);
    if (d < bestD) {
      bestD = d;
      bestI = i;
    }
  }

  var walked = 0.0;
  for (var j = bestI; j < points.length - 1; j++) {
    final segLen = metersBetween(points[j], points[j + 1]);
    walked += segLen;
    if (walked >= lookAheadMeters || j == points.length - 2) {
      return bearingDegrees(from, points[j + 1]);
    }
  }
  return bearingDegrees(from, points.last);
}

/// True se o rumo do GPS está claramente contra a rota traçada (trecho laranja / linha).
bool isHeadingAgainstRoute({
  required LatLng from,
  required double headingDegrees,
  required List<LatLng> routePoints,
  double minErrorDegrees = 100,
  double lookAheadMeters = 35,
}) {
  if (headingDegrees.isNaN || routePoints.length < 2) return false;
  final expected = bearingAlongRouteAhead(
    from,
    routePoints,
    lookAheadMeters: lookAheadMeters,
  );
  if (expected == null) return false;
  return headingDeltaDegrees(headingDegrees, expected) >= minErrorDegrees;
}
