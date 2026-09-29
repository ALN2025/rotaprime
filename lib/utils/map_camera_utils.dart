import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/map_route_fit.dart';

class MapCameraUtils {
  MapCameraUtils._();

  static const defaultCenter = kMapDefaultCenter;

  static LatLng initialCenterForRoute({
    required List<Parada> paradas,
    required List<LatLng> routePoints,
    int? highlightStop,
    LatLng? driver,
  }) {
    if (paradas.any((p) => p.latitude != null && p.longitude != null)) {
      return mapPlanningInitialCenter(
        paradas: paradas,
        driver: driver,
        highlightStop: highlightStop,
      );
    }
    if (routePoints.isNotEmpty) return routePoints.first;
    if (driver != null && isLatLngInContinentalBrazil(driver)) return driver;
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
