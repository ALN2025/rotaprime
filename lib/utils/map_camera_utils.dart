import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';

class MapCameraUtils {
  MapCameraUtils._();

  static const defaultCenter = LatLng(-29.1678, -51.1794);

  static LatLng initialCenterForRoute({
    required List<Parada> paradas,
    required List<LatLng> routePoints,
    int? highlightStop,
  }) {
    if (highlightStop != null) {
      for (final p in paradas) {
        if (p.ordemExibicao == highlightStop &&
            p.latitude != null &&
            p.longitude != null) {
          return LatLng(p.latitude!, p.longitude!);
        }
      }
    }
    for (final p in paradas) {
      if (!p.entregue && !p.falha && p.latitude != null && p.longitude != null) {
        return LatLng(p.latitude!, p.longitude!);
      }
    }
    if (routePoints.isNotEmpty) return routePoints.first;
    for (final p in paradas) {
      if (p.latitude != null && p.longitude != null) {
        return LatLng(p.latitude!, p.longitude!);
      }
    }
    return defaultCenter;
  }

  static List<LatLng> collectRoutePoints(List<Parada> paradas, List<LatLng> routePoints) {
    if (routePoints.isNotEmpty) return routePoints;
    return paradas
        .where((p) => p.latitude != null && p.longitude != null)
        .map((p) => LatLng(p.latitude!, p.longitude!))
        .toList();
  }
}
