import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:rota_prime/app/google_map_style.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/services/clustering_service.dart';
import 'package:rota_prime/utils/google_map_pin_bitmap.dart';
import 'package:rota_prime/utils/map_camera_utils.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/utils/parada_map_markers.dart';
import 'package:rota_prime/utils/rota_map_controller.dart';

/// Mapa Google (Ruas / Escuro) — nomes de ruas nativos, sem tiles de terceiros.
class RouteMapGoogle extends StatefulWidget {
  const RouteMapGoogle({
    super.key,
    required this.paradas,
    required this.routePoints,
    required this.basemap,
    this.rotaMapController,
    this.navigationLegPoints,
    this.legRouteOnly = false,
    this.height,
    this.interactive = true,
    this.selectedParadaId,
    this.driverPosition,
    this.driverHeading = 0,
    this.navigationView = false,
    this.allowRoutePolylines = true,
    this.lightweightMarkers = false,
    this.hideCompletedStops = false,
    this.viewportClusters,
    this.onParadaTap,
    this.onCameraMove,
    this.onCameraIdle,
    this.initialZoom = 13,
  });

  final List<Parada> paradas;
  final List<LatLng> routePoints;
  final List<LatLng>? navigationLegPoints;
  final MapBasemap basemap;
  final RotaMapController? rotaMapController;
  final bool legRouteOnly;
  final double? height;
  final bool interactive;
  final int? selectedParadaId;
  final LatLng? driverPosition;
  final double driverHeading;
  final bool navigationView;
  final bool allowRoutePolylines;
  final bool lightweightMarkers;
  final bool hideCompletedStops;
  final List<MapPinCluster>? viewportClusters;
  final void Function(Parada parada)? onParadaTap;
  final VoidCallback? onCameraMove;
  final VoidCallback? onCameraIdle;
  final double initialZoom;

  @override
  State<RouteMapGoogle> createState() => _RouteMapGoogleState();
}

class _RouteMapGoogleState extends State<RouteMapGoogle> {
  Set<gmaps.Marker> _markers = {};
  Set<gmaps.Polyline> _polylines = {};
  @override
  void initState() {
    super.initState();
    _scheduleMarkerRebuild();
  }

  @override
  void didUpdateWidget(RouteMapGoogle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paradas != widget.paradas ||
        oldWidget.selectedParadaId != widget.selectedParadaId ||
        oldWidget.viewportClusters != widget.viewportClusters ||
        oldWidget.driverPosition != widget.driverPosition ||
        oldWidget.routePoints != widget.routePoints ||
        oldWidget.navigationLegPoints != widget.navigationLegPoints) {
      _scheduleMarkerRebuild();
      _rebuildPolylines();
    }
  }

  void _scheduleMarkerRebuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildMarkers());
  }

  Parada? _paradaById(int id) {
    for (final p in widget.paradas) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool _isSelected(Parada p) =>
      widget.selectedParadaId != null && p.id == widget.selectedParadaId;

  Future<void> _rebuildMarkers() async {
    if (!mounted) return;
    final markers = <gmaps.Marker>{};
    final clusters = widget.viewportClusters;

    if (clusters != null) {
      for (final c in clusters) {
        final p = _paradaById(c.representativeParadaId);
        if (p == null) continue;
        final icon = await googleMapPinIcon(
          c.displayLabel,
          selected: _isSelected(p),
          compact: true,
          deliveryState: pinStateForAddress(widget.paradas, p),
        );
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('c${p.id}'),
            position: RotaMapController.toGoogle(c.latLng),
            icon: icon,
            anchor: const Offset(0.5, 1.0),
            onTap: widget.onParadaTap == null ? null : () => widget.onParadaTap!(p),
          ),
        );
      }
    } else {
      final reps = representativeParadasForMap(
        widget.paradas,
        hideCompleted: widget.hideCompletedStops,
      );
      final points = buildMapMarkerDisplayPoints(widget.paradas);
      final labels = ParadaLabels.mapPinDisplayLabelsForRepresentatives(
        widget.paradas,
        reps,
      );
      for (final p in reps) {
        if (p.latitude == null || p.longitude == null) continue;
        final pos = points[p.id] ?? LatLng(p.latitude!, p.longitude!);
        final label = labels[p.id] ?? '${p.ordemExibicao}';
        final icon = await googleMapPinIcon(
          label,
          selected: _isSelected(p),
          compact: widget.lightweightMarkers,
          deliveryState: pinStateForAddress(widget.paradas, p),
        );
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('p${p.id}'),
            position: RotaMapController.toGoogle(pos),
            icon: icon,
            anchor: const Offset(0.5, 1.0),
            onTap: widget.onParadaTap == null ? null : () => widget.onParadaTap!(p),
          ),
        );
      }
    }

    final driver = widget.driverPosition;
    if (driver != null) {
      final driverIcon = await googleMapDriverIcon(
        navigationMode: widget.navigationView || widget.legRouteOnly,
      );
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('driver'),
          position: RotaMapController.toGoogle(driver),
          icon: driverIcon,
          rotation: widget.driverHeading,
          anchor: const Offset(0.5, 0.52),
          flat: true,
          zIndexInt: 999,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _markers = markers);
  }

  void _rebuildPolylines() {
    if (!widget.allowRoutePolylines) {
      setState(() => _polylines = {});
      return;
    }
    final leg = widget.navigationLegPoints;
    final points = (widget.legRouteOnly && leg != null && leg.length >= 2)
        ? leg
        : widget.routePoints;
    if (points.length < 2) {
      setState(() => _polylines = {});
      return;
    }
    final thin = _thinPolyline(points);
    final gPoints =
        thin.map((p) => RotaMapController.toGoogle(p)).toList(growable: false);
    setState(() {
      _polylines = {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route_halo'),
          points: gPoints,
          color: AppColors.routeLineHalo,
          width: 10,
          geodesic: true,
        ),
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route_core'),
          points: gPoints,
          color: AppColors.routeLineCore,
          width: 5,
          geodesic: true,
        ),
      };
    });
  }

  static List<LatLng> _thinPolyline(List<LatLng> points, {int max = 160}) {
    if (points.length <= max) return points;
    final step = points.length / max;
    final out = <LatLng>[];
    for (var i = 0; i < max; i++) {
      out.add(points[(i * step).floor().clamp(0, points.length - 1)]);
    }
    if (out.last != points.last) out.add(points.last);
    return out;
  }

  Future<void> _onMapCreated(gmaps.GoogleMapController controller) async {
    widget.rotaMapController?.bindGoogle(controller);
    await widget.rotaMapController?.fitToParadas(
      widget.paradas,
      focusNear: widget.driverPosition,
      ultraFast: widget.paradas.length >= 40,
    );
    widget.onCameraIdle?.call();
    _rebuildPolylines();
  }

  @override
  Widget build(BuildContext context) {
    final center = MapCameraUtils.initialCenterForRoute(
      paradas: widget.paradas,
      routePoints: widget.routePoints,
      driver: widget.driverPosition,
    );
    final dark = widget.basemap == MapBasemap.dark;

    final map = gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: RotaMapController.toGoogle(center),
        zoom: widget.initialZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: _onMapCreated,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      liteModeEnabled: false,
      style: dark ? kGoogleMapDarkStyleJson : null,
      mapType: gmaps.MapType.normal,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: widget.interactive,
      tiltGesturesEnabled: widget.interactive,
      onCameraMoveStarted: widget.onCameraMove,
      onCameraMove: (_) => widget.onCameraMove?.call(),
      onCameraIdle: () => widget.onCameraIdle?.call(),
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height, child: map);
    }
    return map;
  }
}
