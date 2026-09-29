import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/map_route_fit.dart';

/// Controla Flutter Map (legado) ou Google Maps (Ruas/Escuro).
class RotaMapController {
  RotaMapController({this.useGoogleMaps = true});

  final bool useGoogleMaps;
  final MapController flutterController = MapController();
  gmaps.GoogleMapController? googleController;
  bool _googleLive = false;
  gmaps.CameraPosition? _lastGoogleCamera;

  void setGoogleLive(bool live) => _googleLive = live;

  bool get _googleReady => useGoogleMaps && _googleLive && googleController != null;

  void bindGoogle(gmaps.GoogleMapController controller) {
    googleController = controller;
    _googleLive = true;
  }

  void dispose() {
    googleController?.dispose();
    flutterController.dispose();
  }

  static gmaps.LatLng toGoogle(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  static LatLng fromGoogle(gmaps.LatLng p) => LatLng(p.latitude, p.longitude);

  void move(LatLng position, double zoom, {Offset offset = Offset.zero}) {
    final g = googleController;
    if (_googleReady && g != null) {
      _lastGoogleCamera = gmaps.CameraPosition(
        target: toGoogle(position),
        zoom: zoom,
        bearing: _lastGoogleCamera?.bearing ?? 0,
        tilt: _lastGoogleCamera?.tilt ?? 0,
      );
      g.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(toGoogle(position), zoom),
      );
      return;
    }
    flutterController.move(position, zoom, offset: offset);
  }

  void rotate(double degrees) {
    final g = googleController;
    if (_googleReady && g != null) {
      final last = _lastGoogleCamera;
      if (last != null) {
        _lastGoogleCamera = gmaps.CameraPosition(
          target: last.target,
          zoom: last.zoom,
          bearing: degrees,
          tilt: last.tilt,
        );
        g.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(_lastGoogleCamera!),
        );
      }
      return;
    }
    flutterController.rotate(degrees);
  }

  Future<void> followDriver(
    LatLng position, {
    required double zoom,
    required double headingDegrees,
    bool rotateWithHeading = true,
    double tilt = 0,
  }) async {
    final g = googleController;
    if (_googleReady && g != null) {
      _lastGoogleCamera = gmaps.CameraPosition(
        target: toGoogle(position),
        zoom: zoom,
        bearing: rotateWithHeading ? headingDegrees : 0,
        tilt: tilt,
      );
      await g.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(_lastGoogleCamera!),
      );
      return;
    }
    flutterController.move(position, zoom);
    if (rotateWithHeading) {
      flutterController.rotate(-headingDegrees);
    }
  }

  Future<void> fitBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.fromLTRB(48, 100, 48, 220),
    double maxZoom = 17.5,
  }) async {
    final g = googleController;
    if (_googleReady && g != null) {
      await g.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(
          gmaps.LatLngBounds(
            southwest: toGoogle(bounds.southWest),
            northeast: toGoogle(bounds.northEast),
          ),
          math.max(padding.left + padding.right, 48.0),
        ),
      );
      return;
    }
    flutterController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: padding, maxZoom: maxZoom),
    );
  }

  void fitCamera(CameraFit fit) {
    if (_googleReady) return;
    flutterController.fitCamera(fit);
  }

  LatLngBounds get visibleBounds {
    return flutterController.camera.visibleBounds;
  }

  Future<LatLngBounds?> visibleBoundsAsync() async {
    final g = googleController;
    if (_googleReady && g != null) {
      try {
        final region = await g.getVisibleRegion();
        return LatLngBounds(
          LatLng(
            math.min(region.northeast.latitude, region.southwest.latitude),
            math.min(region.northeast.longitude, region.southwest.longitude),
          ),
          LatLng(
            math.max(region.northeast.latitude, region.southwest.latitude),
            math.max(region.northeast.longitude, region.southwest.longitude),
          ),
        );
      } catch (_) {
        return null;
      }
    }
    return flutterController.camera.visibleBounds;
  }

  Future<void> fitToParadas(
    List<Parada> paradas, {
    EdgeInsets padding = const EdgeInsets.fromLTRB(48, 100, 48, 220),
    double maxZoom = 16,
    double singleStopZoom = 14,
    LatLng? focusNear,
    bool ultraFast = false,
  }) async {
    final g = googleController;
    if (_googleReady && g != null) {
      await fitGoogleMapToParadas(
        g,
        paradas,
        padding: padding,
        maxZoom: maxZoom,
        singleStopZoom: singleStopZoom,
        focusNear: focusNear,
        ultraFast: ultraFast,
      );
      return;
    }
    fitMapControllerToParadas(
      flutterController,
      paradas,
      padding: padding,
      maxZoom: maxZoom,
      singleStopZoom: singleStopZoom,
      focusNear: focusNear,
      ultraFast: ultraFast,
    );
  }
}

Future<void> fitGoogleMapToParadas(
  gmaps.GoogleMapController controller,
  List<Parada> paradas, {
  EdgeInsets padding = const EdgeInsets.fromLTRB(48, 100, 48, 220),
  double maxZoom = 16,
  double singleStopZoom = 14,
  LatLng? focusNear,
  bool ultraFast = false,
}) async {
  final points = mapFitPointsFromParadas(paradas, regionAnchor: focusNear);
  if (points.isEmpty) {
    if (focusNear != null && isLatLngInContinentalBrazil(focusNear)) {
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(RotaMapController.toGoogle(focusNear), 12),
      );
    }
    return;
  }
  if (points.length == 1) {
    await controller.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        RotaMapController.toGoogle(points.first),
        singleStopZoom,
      ),
    );
    return;
  }

  final n = paradas.length;
  final spread = mapPointsSpreadKm(points);
  if (ultraFast || n >= 40 || spread > 65) {
    final regional = mapRegionalCamera(
      paradas: paradas,
      driver: focusNear,
      stopCount: n,
    );
    await controller.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        RotaMapController.toGoogle(regional.center),
        regional.zoom.clamp(6.8, maxZoom),
      ),
    );
    return;
  }

  var minLat = points.first.latitude;
  var maxLat = points.first.latitude;
  var minLng = points.first.longitude;
  var maxLng = points.first.longitude;
  for (final p in points) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLng = math.min(minLng, p.longitude);
    maxLng = math.max(maxLng, p.longitude);
  }

  await controller.animateCamera(
    gmaps.CameraUpdate.newLatLngBounds(
      gmaps.LatLngBounds(
        southwest: gmaps.LatLng(minLat, minLng),
        northeast: gmaps.LatLng(maxLat, maxLng),
      ),
      math.max(padding.left + padding.right, 48.0),
    ),
  );
}

void fitRotaMapControllerToParadas(
  RotaMapController controller,
  List<Parada> paradas, {
  EdgeInsets padding = const EdgeInsets.fromLTRB(48, 100, 48, 220),
  double maxZoom = 16,
  double singleStopZoom = 14,
  double minZoom = 9,
  LatLng? focusNear,
  bool ultraFast = false,
}) {
  if (controller._googleReady) {
    controller.fitToParadas(
      paradas,
      padding: padding,
      maxZoom: maxZoom,
      singleStopZoom: singleStopZoom,
      focusNear: focusNear,
      ultraFast: ultraFast,
    );
    return;
  }
  fitMapControllerToParadas(
    controller.flutterController,
    paradas,
    padding: padding,
    maxZoom: maxZoom,
    singleStopZoom: singleStopZoom,
    minZoom: minZoom,
    focusNear: focusNear,
    ultraFast: ultraFast,
  );
}
