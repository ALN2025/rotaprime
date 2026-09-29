import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/map_geo.dart';

/// Caixa aproximada de cada UF — enquadra RS, RJ, etc., nunca o Brasil inteiro.
class _UfBox {
  const _UfBox(this.uf, this.minLat, this.maxLat, this.minLng, this.maxLng);

  final String uf;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  LatLng get center => LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      );

  bool contains(LatLng p) =>
      p.latitude >= minLat &&
      p.latitude <= maxLat &&
      p.longitude >= minLng &&
      p.longitude <= maxLng;
}

// Limites simplificados (continental). Sobreposições resolvem pelo centro mais próximo.
const _ufBoxes = <_UfBox>[
  _UfBox('AC', -11.15, -7.05, -73.99, -66.62),
  _UfBox('AL', -10.50, -8.81, -38.01, -35.15),
  _UfBox('AM', -9.82, 2.25, -73.80, -56.10),
  _UfBox('AP', 1.00, 4.44, -54.88, -49.87),
  _UfBox('BA', -18.35, -8.53, -46.62, -37.34),
  _UfBox('CE', -7.86, -2.78, -41.42, -37.25),
  _UfBox('DF', -16.05, -15.50, -48.28, -47.30),
  _UfBox('ES', -21.30, -17.89, -41.88, -39.68),
  _UfBox('GO', -19.50, -12.39, -53.25, -45.90),
  _UfBox('MA', -10.26, -1.04, -48.75, -41.80),
  _UfBox('MG', -22.92, -14.23, -51.05, -39.86),
  _UfBox('MS', -24.06, -17.17, -58.17, -50.92),
  _UfBox('MT', -18.04, -7.35, -61.63, -50.22),
  _UfBox('PA', -9.84, 2.59, -58.90, -46.06),
  _UfBox('PB', -8.30, -6.02, -38.77, -34.79),
  _UfBox('PE', -9.48, -7.32, -41.36, -34.86),
  _UfBox('PI', -10.93, -2.74, -45.99, -40.37),
  _UfBox('PR', -26.72, -22.51, -54.62, -48.02),
  _UfBox('RJ', -23.37, -20.76, -44.89, -40.95),
  _UfBox('RN', -6.98, -4.83, -38.58, -34.97),
  _UfBox('RO', -13.68, -7.97, -66.62, -59.78),
  _UfBox('RR', 0.05, 5.27, -64.82, -59.18),
  _UfBox('RS', -33.75, -27.08, -57.65, -49.69),
  _UfBox('SC', -29.35, -25.96, -53.84, -48.35),
  _UfBox('SE', -11.57, -9.51, -38.24, -36.39),
  _UfBox('SP', -25.31, -19.78, -53.11, -44.16),
  _UfBox('TO', -13.47, -5.17, -50.73, -45.72),
];

/// UF do ponto (ex.: Caxias → RS, Niterói → RJ).
String? brazilUfAt(LatLng p) {
  if (!isLatLngInContinentalBrazil(p)) return null;
  for (final box in _ufBoxes) {
    if (box.contains(p)) return box.uf;
  }
  var best = _ufBoxes.first;
  var bestKm = double.infinity;
  for (final box in _ufBoxes) {
    final d = _approxKm(p, box.center);
    if (d < bestKm) {
      bestKm = d;
      best = box;
    }
  }
  return best.uf;
}

_UfBox? _boxForUf(String uf) {
  for (final b in _ufBoxes) {
    if (b.uf == uf) return b;
  }
  return null;
}

double _approxKm(LatLng a, LatLng b) {
  final midLat = (a.latitude + b.latitude) / 2;
  final dLat = (a.latitude - b.latitude) * 111.0;
  final dLng = (a.longitude - b.longitude) *
      111.0 *
      math.cos(midLat * math.pi / 180).abs().clamp(0.2, 1.0);
  return math.sqrt(dLat * dLat + dLng * dLng);
}

/// UF da rota: GPS do entregador ou maioria das paradas geocodadas.
String? mapDeliveryUf({
  required List<Parada> paradas,
  LatLng? driver,
}) {
  if (driver != null && isLatLngInContinentalBrazil(driver)) {
    return brazilUfAt(driver);
  }
  final counts = <String, int>{};
  for (final p in paradas) {
    if (p.latitude == null || p.longitude == null) continue;
    final pt = LatLng(p.latitude!, p.longitude!);
    final uf = brazilUfAt(pt);
    if (uf == null) continue;
    counts[uf] = (counts[uf] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

List<LatLng> filterPointsToUf(List<LatLng> points, String uf) {
  return points.where((p) => brazilUfAt(p) == uf).toList();
}

LatLng? brazilUfCenter(String uf) => _boxForUf(uf)?.center;

/// Zoom para enxergar o estado (RS, RJ…) sem abrir o país.
double mapStateOverviewZoom(String uf) {
  switch (uf) {
    case 'SP':
    case 'MG':
    case 'BA':
    case 'AM':
    case 'PA':
    case 'RS':
      return 7.2;
    case 'RJ':
    case 'DF':
    case 'ES':
    case 'SC':
    case 'PR':
      return 7.8;
    default:
      return 7.5;
  }
}
