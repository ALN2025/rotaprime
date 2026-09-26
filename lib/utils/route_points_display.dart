import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/rota.dart';

const _distance = Distance();

/// Garante linha desde a origem gravada na otimização (GPS ou 1ª parada).
List<LatLng> routePointsForDisplay(List<LatLng> points, RotaRecord? rota) {
  if (points.length < 2 || rota == null) return points;
  if (rota.origemLatitude == null || rota.origemLongitude == null) return points;

  final origin = LatLng(rota.origemLatitude!, rota.origemLongitude!);
  if (_distance(origin, points.first) < 20) return points;
  return [origin, ...points];
}
