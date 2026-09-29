import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/brazil_map_region.dart';
import 'package:rota_prime/utils/map_geo.dart';

export 'package:rota_prime/utils/map_geo.dart'
    show
        kMapDefaultCenter,
        isLatLngInContinentalBrazil,
        mapCityZoomForSpreadKm,
        mapPointsSpreadKm;

List<LatLng> _filterNearMedian(List<LatLng> raw, double maxKmFromMedian) {
  if (raw.length <= 4) return raw;
  final med = mapMedianCenter(raw);
  final filtered =
      raw.where((p) => mapApproxKm(p, med) <= maxKmFromMedian).toList();
  return filtered.length >= 2 ? filtered : raw;
}

List<LatLng> _filterToDeliveryUf(List<LatLng> raw, String? uf) {
  if (uf == null || raw.length <= 4) return raw;
  final inUf = filterPointsToUf(raw, uf);
  if (inUf.length >= math.max(2, (raw.length * 0.25).ceil())) {
    return inUf;
  }
  return raw;
}

/// Ignora geocodes errados / fora da UF do entregador (mapa cinza / ANR).
List<LatLng> mapFitPointsFromParadas(
  List<Parada> paradas, {
  LatLng? regionAnchor,
}) {
  final raw = paradas
      .where((p) => p.latitude != null && p.longitude != null)
      .map((p) => LatLng(p.latitude!, p.longitude!))
      .where(isLatLngInContinentalBrazil)
      .toList();
  if (raw.isEmpty) return raw;

  final uf = mapDeliveryUf(
    paradas: paradas,
    driver: regionAnchor,
  );
  var scoped = _filterToDeliveryUf(raw, uf);
  if (scoped.length <= 4) return scoped;

  var filtered = _filterNearMedian(scoped, 55);
  if (filtered.length < math.max(2, (scoped.length * 0.35).ceil())) {
    filtered = _filterNearMedian(scoped, 85);
  }
  return filtered;
}

/// Centro inicial do mapa: cluster das paradas ou GPS do entregador na mesma região.
LatLng mapPlanningInitialCenter({
  required List<Parada> paradas,
  LatLng? driver,
  int? highlightStop,
}) {
  if (highlightStop != null) {
    for (final p in paradas) {
      if (p.ordemExibicao == highlightStop &&
          p.latitude != null &&
          p.longitude != null) {
        final pt = LatLng(p.latitude!, p.longitude!);
        if (isLatLngInContinentalBrazil(pt)) return pt;
      }
    }
  }

  final cluster = mapFitPointsFromParadas(paradas, regionAnchor: driver);
  if (cluster.isNotEmpty) {
    final center = mapMedianCenter(cluster);
    if (driver != null && isLatLngInContinentalBrazil(driver)) {
      if (mapApproxKm(driver, center) <= 120) return driver;
    }
    return center;
  }

  if (driver != null && isLatLngInContinentalBrazil(driver)) return driver;

  final uf = mapDeliveryUf(paradas: paradas, driver: driver);
  final ufCenter = uf != null ? brazilUfCenter(uf) : null;
  if (ufCenter != null) return ufCenter;

  for (final p in paradas) {
    if (p.latitude != null && p.longitude != null) {
      final pt = LatLng(p.latitude!, p.longitude!);
      if (isLatLngInContinentalBrazil(pt)) return pt;
    }
  }
  return kMapDefaultCenter;
}

({LatLng center, double zoom}) mapRegionalCamera({
  required List<Parada> paradas,
  LatLng? driver,
  int stopCount = 0,
}) {
  final cluster = mapFitPointsFromParadas(paradas, regionAnchor: driver);
  final uf = mapDeliveryUf(paradas: paradas, driver: driver);
  final center = cluster.isNotEmpty
      ? mapMedianCenter(cluster)
      : (driver != null && isLatLngInContinentalBrazil(driver)
          ? driver
          : (uf != null ? brazilUfCenter(uf) : null) ?? kMapDefaultCenter);

  if (cluster.length >= 2) {
    final spread = mapPointsSpreadKm(cluster);
    if (spread <= 65) {
      return (center: center, zoom: mapCityZoomForSpreadKm(spread));
    }
    if (uf != null) {
      final inUf = filterPointsToUf(cluster, uf);
      if (inUf.length >= 2) {
        final ufSpread = mapPointsSpreadKm(inUf);
        if (ufSpread <= 120) {
          return (
            center: mapMedianCenter(inUf),
            zoom: mapCityZoomForSpreadKm(ufSpread.clamp(0, 45)).clamp(9.0, 12.0),
          );
        }
      }
    }
  }

  if (uf != null) {
    var z = mapStateOverviewZoom(uf);
    if (stopCount > 70) z = (z - 0.3).clamp(6.8, 9.0);
    return (center: brazilUfCenter(uf) ?? center, zoom: z);
  }

  final z = stopCount > 50 ? 9.0 : 10.5;
  return (center: center, zoom: z);
}

/// Enquadra o mapa na região das entregas (cidade/UF), não no país inteiro.
void fitMapControllerToParadas(
  MapController controller,
  List<Parada> paradas, {
  EdgeInsets padding = const EdgeInsets.fromLTRB(48, 100, 48, 220),
  double maxZoom = 16,
  double singleStopZoom = 14,
  double minZoom = 9,
  LatLng? focusNear,
  bool ultraFast = false,
}) {
  final n = paradas.length;
  final points = mapFitPointsFromParadas(paradas, regionAnchor: focusNear);
  if (points.isEmpty) {
    if (focusNear != null && isLatLngInContinentalBrazil(focusNear)) {
      final uf = brazilUfAt(focusNear);
      controller.move(
        focusNear,
        uf != null ? mapStateOverviewZoom(uf) : 10,
      );
    }
    return;
  }
  if (points.length == 1) {
    controller.move(points.first, singleStopZoom);
    return;
  }

  final spread = mapPointsSpreadKm(points);
  final regional = mapRegionalCamera(
    paradas: paradas,
    driver: focusNear,
    stopCount: n,
  );

  if (ultraFast || n >= 40 || spread > 65) {
    controller.move(regional.center, regional.zoom.clamp(6.8, maxZoom));
    return;
  }

  controller.fitCamera(
    CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: padding,
      maxZoom: maxZoom,
      minZoom: minZoom,
    ),
  );
}
