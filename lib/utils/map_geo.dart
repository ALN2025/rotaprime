import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Centro padrão (Caxias do Sul) — só se não houver paradas/GPS.
const kMapDefaultCenter = LatLng(-29.1678, -51.1794);

/// Evita geocode fora do Brasil continental (zoom “país inteiro”).
bool isLatLngInContinentalBrazil(LatLng p) {
  return p.latitude >= -34.0 &&
      p.latitude <= 5.5 &&
      p.longitude >= -74.0 &&
      p.longitude <= -32.0;
}

double mapApproxKm(LatLng a, LatLng b) {
  final midLat = (a.latitude + b.latitude) / 2;
  final dLat = (a.latitude - b.latitude) * 111.0;
  final dLng = (a.longitude - b.longitude) *
      111.0 *
      math.cos(midLat * math.pi / 180).abs().clamp(0.2, 1.0);
  return math.sqrt(dLat * dLat + dLng * dLng);
}

LatLng mapMedianCenter(List<LatLng> points) {
  final lats = points.map((p) => p.latitude).toList()..sort();
  final lngs = points.map((p) => p.longitude).toList()..sort();
  return LatLng(lats[lats.length ~/ 2], lngs[lngs.length ~/ 2]);
}

/// Maior distância entre dois pontos do conjunto.
double mapPointsSpreadKm(List<LatLng> points) {
  if (points.length < 2) return 0;
  var maxKm = 0.0;
  for (var i = 0; i < points.length; i++) {
    for (var j = i + 1; j < points.length; j++) {
      final d = mapApproxKm(points[i], points[j]);
      if (d > maxKm) maxKm = d;
    }
  }
  return maxKm;
}

/// Zoom de “cidade/bairro”.
double mapCityZoomForSpreadKm(double spreadKm) {
  if (spreadKm <= 3) return 15;
  if (spreadKm <= 8) return 14;
  if (spreadKm <= 18) return 13;
  if (spreadKm <= 35) return 12;
  return 11;
}
