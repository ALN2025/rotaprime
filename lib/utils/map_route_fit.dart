import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';

/// Enquadra o mapa nas paradas (você pode estar em Caxias; pins em outro estado).
void fitMapControllerToParadas(
  MapController controller,
  List<Parada> paradas, {
  EdgeInsets padding = const EdgeInsets.fromLTRB(48, 100, 48, 220),
  double maxZoom = 16,
  double singleStopZoom = 14,
}) {
  final points = paradas
      .where((p) => p.latitude != null && p.longitude != null)
      .map((p) => LatLng(p.latitude!, p.longitude!))
      .toList();
  if (points.isEmpty) return;
  if (points.length == 1) {
    controller.move(points.first, singleStopZoom);
    return;
  }
  controller.fitCamera(
    CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: padding,
      maxZoom: maxZoom,
    ),
  );
}
