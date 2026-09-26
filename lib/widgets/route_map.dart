import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/services/map_tile_prefetch.dart';
import 'package:rota_prime/services/offline_first_tile_provider.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/map_camera_utils.dart';
import 'package:rota_prime/utils/map_route_fit.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/utils/parada_map_markers.dart';
import 'package:rota_prime/widgets/rota_driver_map_marker.dart';

class RouteMap extends StatefulWidget {
  /// Deslocamento vertical do ícone em relação ao ponto GPS (libera nome da rua).
  static const double streetLabelClearance = 26.0;
  static const double _pinAnchorExtra = 10.0 + streetLabelClearance;

  const RouteMap({
    super.key,
    required this.paradas,
    required this.routePoints,
    this.navigationLegPoints,
    this.legRouteOnly = false,
    this.height,
    this.interactive = true,
    this.highlightStop,
    this.selectedParadaId,
    this.driverPosition,
    this.driverHeading = 0,
    this.navigationView = false,
    this.mapRotationDegrees = 0,
    this.mapController,
    this.onParadaTap,
    this.basemap = MapBasemap.standard,
    this.initialZoom = 13,
    this.allowRotation = true,
    this.onUserMapGesture,
    this.showStopCallouts = false,
    this.allowRoutePolylines = true,
    this.fastTileLayer = false,
    this.hideCompletedStops = false,
  });

  final List<Parada> paradas;
  final List<LatLng> routePoints;
  /// No modo entrega, desenha só este trecho (ignora [routePoints]).
  final List<LatLng>? navigationLegPoints;
  /// Entrega ativa: só o trecho até a parada alvo (não a rota inteira).
  final bool legRouteOnly;
  final double? height;
  final bool interactive;
  final int? highlightStop;
  final int? selectedParadaId;
  final LatLng? driverPosition;
  final double driverHeading;
  final bool navigationView;
  final double mapRotationDegrees;
  final MapController? mapController;
  final void Function(Parada parada)? onParadaTap;
  final MapBasemap basemap;
  final double initialZoom;
  final bool allowRotation;
  final VoidCallback? onUserMapGesture;
  /// Desliga o balão de endereço no pin (evita tarja no meio do mapa).
  final bool showStopCallouts;
  /// Grátis / sem OSRM: nunca desenha linha laranja (só pins + entregador).
  final bool allowRoutePolylines;
  /// Menos tiles em buffer — mapa mais leve na entrega ativa.
  final bool fastTileLayer;
  /// Oculta pins já entregues / não entregues (mapa só com o que falta).
  final bool hideCompletedStops;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> with SingleTickerProviderStateMixin {
  late LatLng _initialCenter;
  late double _initialZoom;
  double _mapZoom = 15;
  AnimationController? _driverMoveCtrl;
  LatLng? _driverAnimFrom;
  LatLng? _driverAnimTo;
  double _driverHeadingFrom = 0;
  double _driverHeadingTo = 0;

  /// Espessura da rota no eixo da rua — proporcional ao zoom (referência Circuit).
  double _circuitStreetStroke(double zoom) {
    final z = zoom.clamp(14.0, 19.0);
    // Faixa branca da rua no tile Esri ≈ 18–28 px; linha ~40% (Circuit).
    final streetBand = 16.0 + (z - 15.0) * 3.2;
    return (streetBand * 0.42).clamp(6.5, 12.5);
  }

  @override
  void initState() {
    super.initState();
    _applyInitialCamera(widget);
    _mapZoom = widget.initialZoom;
    MapTilePrefetch.cacheDirectory();
    _driverMoveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    final p = widget.driverPosition;
    if (p != null) {
      _driverAnimFrom = p;
      _driverAnimTo = p;
      _driverHeadingTo = widget.driverHeading;
    }
  }

  @override
  void dispose() {
    _driverMoveCtrl?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCoords = oldWidget.paradas
        .where((p) => p.latitude != null && p.longitude != null)
        .length;
    final newCoords = widget.paradas
        .where((p) => p.latitude != null && p.longitude != null)
        .length;
    if (newCoords > 0 && (oldCoords == 0 || newCoords > oldCoords)) {
      _applyInitialCamera(widget);
      final ctrl = widget.mapController;
      if (ctrl != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          fitMapControllerToParadas(ctrl, widget.paradas);
        });
      }
    }
    _syncDriverAnimation(oldWidget);
  }

  void _syncDriverAnimation(RouteMap oldWidget) {
    final next = widget.driverPosition;
    if (next == null) {
      _driverAnimFrom = null;
      _driverAnimTo = null;
      return;
    }
    if (next == oldWidget.driverPosition &&
        widget.driverHeading == oldWidget.driverHeading) {
      return;
    }
    _driverAnimFrom = _displayDriverPosition ?? oldWidget.driverPosition ?? next;
    _driverAnimTo = next;
    _driverHeadingFrom = _displayDriverHeading;
    _driverHeadingTo = widget.driverHeading;
    _driverMoveCtrl?.forward(from: 0);
  }

  LatLng? get _displayDriverPosition {
    final to = _driverAnimTo ?? widget.driverPosition;
    if (to == null) return null;
    final from = _driverAnimFrom ?? to;
    final t = Curves.easeOutCubic.transform(_driverMoveCtrl?.value ?? 1.0);
    if (t >= 1.0) return to;
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  double get _displayDriverHeading {
    final to = _driverAnimTo != null ? _driverHeadingTo : widget.driverHeading;
    final from = _driverHeadingFrom;
    final t = Curves.easeOutCubic.transform(_driverMoveCtrl?.value ?? 1.0);
    if (t >= 1.0) return to;
    var delta = to - from;
    while (delta > 180) {
      delta -= 360;
    }
    while (delta < -180) {
      delta += 360;
    }
    return from + delta * t;
  }

  void _applyInitialCamera(RouteMap w) {
    _initialCenter = MapCameraUtils.initialCenterForRoute(
      paradas: w.paradas,
      routePoints: w.routePoints,
      highlightStop: w.highlightStop,
    );
    _initialZoom = w.initialZoom;
  }

  Parada? _paradaById(int id) {
    for (final p in widget.paradas) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool _sameMapPin(Parada a, Parada b) => sameMapPinGroup(a, b);

  bool _isSelected(Parada p) {
    final selId = widget.selectedParadaId;
    if (selId == null) return false;
    if (p.id == selId) return true;
    final sel = _paradaById(selId);
    if (sel != null) return _sameMapPin(p, sel);
    return false;
  }

  bool _isHighlighted(Parada p) {
    if (widget.selectedParadaId != null) return false;
    if (widget.highlightStop == null) return false;
    if (p.ordemExibicao == widget.highlightStop) return true;
    return false;
  }

  List<Widget> _routePolylines() {
    if (!widget.allowRoutePolylines) return const [];
    final List<LatLng> points;
    if (widget.legRouteOnly || widget.navigationView) {
      final leg = widget.navigationLegPoints;
      if (leg == null || leg.length < 2) return const [];
      points = leg;
    } else {
      if (widget.routePoints.length < 2) return const [];
      points = widget.routePoints;
    }

    final legOnly = widget.legRouteOnly;
    if (legOnly) {
      final band = _circuitStreetStroke(_mapZoom);
      return [
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              strokeWidth: band,
              color: AppColors.activeDeliveryRouteEdge,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              strokeWidth: band,
              color: AppColors.activeDeliveryRouteFill,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        ),
      ];
    }

    final stroke = widget.navigationView ? 5.0 : 4.0;
    return [
      PolylineLayer(
        polylines: [
          Polyline(
            points: points,
            strokeWidth: stroke + 4.0,
            color: AppColors.routeLineHalo,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        ],
      ),
      PolylineLayer(
        polylines: [
          Polyline(
            points: points,
            strokeWidth: stroke,
            color: AppColors.routeLineCore,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        ],
      ),
    ];
  }

  MapBasemap get _effectiveBasemap => widget.basemap;

  List<Widget> _basemapTileLayers(MapBasemap basemap) {
    final pan = widget.fastTileLayer ? 1 : 2;
    final layers = <Widget>[
      _mapTileLayer(
        basemap: basemap,
        urlTemplate: basemap.urlTemplate,
        maxNativeZoom: basemap.maxNativeZoom,
        labelsOverlay: false,
        panBuffer: pan,
        retina: basemap.retinaOnServer,
      ),
    ];
    final overlays = basemap.labelOverlays ?? const [];
    final labelMaxZ = basemap.labelsMaxNativeZoom ?? basemap.maxNativeZoom;
    for (var i = 0; i < overlays.length; i++) {
      layers.add(
        _mapTileLayer(
          basemap: basemap,
          urlTemplate: overlays[i],
          maxNativeZoom: labelMaxZ,
          labelsOverlay: true,
          labelOverlayIndex: i,
          panBuffer: pan,
          retina: false,
        ),
      );
    }
    return layers;
  }

  Widget _mapTileLayer({
    required MapBasemap basemap,
    required String urlTemplate,
    required int maxNativeZoom,
    required bool labelsOverlay,
    required int panBuffer,
    required bool retina,
    int labelOverlayIndex = 0,
  }) {
    return TileLayer(
      urlTemplate: urlTemplate,
      subdomains: basemap.subdomains ?? const [],
      userAgentPackageName: 'com.rotaprime.rota_prime',
      maxNativeZoom: maxNativeZoom,
      maxZoom: MapBasemap.appMaxZoom,
      panBuffer: panBuffer,
      retinaMode: retina,
      tileProvider: OfflineFirstTileProvider(
        basemap: basemap,
        labelsOverlay: labelsOverlay,
        labelOverlayIndex: labelOverlayIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _effectiveBasemap;
    final stopMarkers = representativeParadasForMap(
      widget.paradas,
      hideCompleted: widget.hideCompletedStops,
    )
      ..sort((a, b) {
        final sa = _isSelected(a);
        final sb = _isSelected(b);
        if (sa == sb) return 0;
        return sa ? 1 : -1;
      });

    return SizedBox(
      height: widget.height,
      child: FlutterMap(
        mapController: widget.mapController,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: _initialZoom,
          initialRotation: widget.mapRotationDegrees,
          minZoom: 5,
          maxZoom: MapBasemap.appMaxZoom,
          backgroundColor: AppColors.background,
          interactionOptions: InteractionOptions(
            flags: widget.interactive
                ? (widget.allowRotation
                    ? InteractiveFlag.all
                    : InteractiveFlag.all & ~InteractiveFlag.rotate)
                : InteractiveFlag.none,
            enableMultiFingerGestureRace: true,
            rotationThreshold: 12,
          ),
          onPositionChanged: (camera, hasGesture) {
            final z = camera.zoom;
            if ((z - _mapZoom).abs() > 0.08) {
              setState(() => _mapZoom = z);
            }
            if (hasGesture) widget.onUserMapGesture?.call();
          },
        ),
        children: [
          ..._basemapTileLayers(tiles),
          ..._routePolylines(),
          MarkerLayer(
            markers: [
              for (final p in stopMarkers)
                Marker(
                  point: mapMarkerDisplayPoint(widget.paradas, p),
                  width: _markerWidth(p),
                  height: _markerHeight(p),
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onParadaTap == null ? null : () => widget.onParadaTap!(p),
                    child: _StopPin(
                      allParadas: widget.paradas,
                      parada: p,
                      selected: _isSelected(p),
                      highlighted: _isHighlighted(p),
                      deliveryMode: widget.legRouteOnly,
                      showMapCallout: widget.showStopCallouts &&
                          !widget.legRouteOnly &&
                          !widget.navigationView &&
                          _isSelected(p),
                    ),
                  ),
                ),
              if (_displayDriverPosition != null)
                Marker(
                  point: _displayDriverPosition!,
                  width: widget.navigationView ? 48 : 36,
                  height: widget.navigationView ? 48 : 36,
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: _displayDriverHeading * math.pi / 180,
                    child: RotaDriverMapMarker(
                      navigationMode: widget.navigationView,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  double _pinSize(Parada p) {
    if (_isSelected(p)) return 58;
    if (_isHighlighted(p)) return 46;
    if (mapPinGroupIsFinished(widget.paradas, p)) return 36;
    return widget.legRouteOnly ? 34 : (widget.navigationView ? 28 : 30);
  }

  bool _showSelectedCallout(Parada p) =>
      _isSelected(p) && widget.showStopCallouts && !widget.legRouteOnly;

  double _markerWidth(Parada p) {
    if (_showSelectedCallout(p)) return 172;
    return _pinSize(p);
  }

  double _markerHeight(Parada p) {
    final anchor = widget.legRouteOnly ? 6.0 : RouteMap._pinAnchorExtra;
    var h = _pinSize(p) + anchor;
    if (_showSelectedCallout(p)) {
      h += 72;
    }
    return h;
  }
}

class _StopPin extends StatelessWidget {
  const _StopPin({
    required this.allParadas,
    required this.parada,
    required this.selected,
    required this.highlighted,
    this.deliveryMode = false,
    this.showMapCallout = false,
  });

  final List<Parada> allParadas;
  final Parada parada;
  final bool selected;
  final bool highlighted;
  final bool deliveryMode;
  final bool showMapCallout;

  MapPinDeliveryState get _state => pinStateForAddress(allParadas, parada);

  Color get _fillColor {
    switch (_state) {
      case MapPinDeliveryState.delivered:
        return AppColors.successGreen;
      case MapPinDeliveryState.failed:
        return AppColors.stopFailed;
      case MapPinDeliveryState.pending:
        return (selected || highlighted) ? AppColors.orange : AppColors.stopPending;
    }
  }

  IconData? get _icon {
    switch (_state) {
      case MapPinDeliveryState.delivered:
        return Icons.check;
      case MapPinDeliveryState.failed:
        return Icons.close;
      case MapPinDeliveryState.pending:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinBody = _buildPinBody();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMapCallout) ...[
          _MapStopCallout(allParadas: allParadas, parada: parada),
          const SizedBox(height: 6),
        ],
        pinBody,
        if (deliveryMode)
          CustomPaint(
            size: const Size(14, 10),
            painter: _PinNeedlePainter(color: _fillColor),
          )
        else ...[
          const SizedBox(height: 2),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _fillColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
          const SizedBox(height: RouteMap.streetLabelClearance),
        ],
      ],
    );
  }

  Widget _buildPinBody() {
    final delivered = _state == MapPinDeliveryState.delivered;
    final showOrderNumber = _state == MapPinDeliveryState.pending || selected;
    final inner = Container(
      width: selected ? 40 : (highlighted ? 34 : 28),
      height: selected ? 40 : (highlighted ? 34 : 28),
      decoration: BoxDecoration(
        color: _fillColor.withValues(alpha: delivered && !selected ? 0.82 : 1),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.orange : Colors.white,
          width: selected ? 4 : (highlighted ? 3 : 2),
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.orange.withValues(alpha: 0.85)
                : (_state == MapPinDeliveryState.failed
                    ? AppColors.stopFailed.withValues(alpha: 0.45)
                    : (deliveryMode ? Colors.black87 : Colors.black54)),
            blurRadius: selected ? 14 : (deliveryMode ? 6 : 4),
            spreadRadius: selected ? 3 : (deliveryMode ? 1 : 0),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: showOrderNumber
          ? Text(
              ParadaLabels.mapPinLabel(allParadas, parada),
              style: TextStyle(
                color: ParadaLabels.isLateAddedPackage(parada) ? Colors.amber : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: ParadaLabels.isLateAddedPackage(parada)
                    ? (selected ? 11 : 9)
                    : (selected ? 15 : (highlighted ? 12 : 10)),
              ),
            )
          : Icon(_icon, color: Colors.white, size: selected ? 20 : 14),
    );

    if (!selected) return inner;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        inner,
      ],
    );

  }
}

class _MapStopCallout extends StatelessWidget {
  const _MapStopCallout({required this.allParadas, required this.parada});

  final List<Parada> allParadas;
  final Parada parada;

  @override
  Widget build(BuildContext context) {
    final address = parada.destinationAddress;
    final short = address.length > 42 ? '${address.substring(0, 42)}…' : address;
    final pkgs = ParadaLabels.packageCountAtStop(allParadas, parada);
    final orders = ParadaLabels.packageOrderLabelsAtStop(allParadas, parada);
    final state = pinStateForAddress(allParadas, parada);
    final statusLabel = switch (state) {
      MapPinDeliveryState.delivered => 'Entregue',
      MapPinDeliveryState.failed => 'Não entregue',
      MapPinDeliveryState.pending => 'Pendente',
    };
    final statusColor = switch (state) {
      MapPinDeliveryState.delivered => AppColors.successGreen,
      MapPinDeliveryState.failed => AppColors.stopFailed,
      MapPinDeliveryState.pending => AppColors.orange,
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 168),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ParadaLabels.deliveryReferenceLine(parada),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            ParadaLabels.mapCalloutTitle(allParadas, parada),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.orange),
                const SizedBox(width: 4),
                Text(
                  orders.length > 1 ? orders.join(', ') : orders.first,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                if (pkgs > 1) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.inventory_2, size: 12, color: AppColors.orange.withValues(alpha: 0.9)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            short,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.25),
          ),
        ],
      ),
    );
  }
}

/// Ponta do pin na coordenada exata (modo entrega).
class _PinNeedlePainter extends CustomPainter {
  _PinNeedlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _PinNeedlePainter oldDelegate) =>
      oldDelegate.color != color;
}
