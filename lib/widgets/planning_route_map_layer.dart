import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/app/map_performance.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/services/clustering_service.dart';
import 'package:rota_prime/utils/route_map_stamp.dart';
import 'package:rota_prime/utils/rota_map_controller.dart';
import 'package:rota_prime/widgets/route_map.dart';

/// Mapa da tela de planejamento — rebuild só quando paradas/rota mudam de verdade.
class PlanningRouteMapLayer extends ConsumerWidget {
  const PlanningRouteMapLayer({
    super.key,
    required this.rotaMapController,
    required this.selectedParadaId,
    required this.onParadaTap,
    this.viewportClusters,
    this.pinIconStyles,
    this.onCameraMove,
    this.onCameraIdle,
  });

  final RotaMapController rotaMapController;
  final int? selectedParadaId;
  final void Function(Parada parada) onParadaTap;
  final List<MapPinCluster>? viewportClusters;
  final Map<String, TextStyle>? pinIconStyles;
  final VoidCallback? onCameraMove;
  final VoidCallback? onCameraIdle;

  static const maxStopsFullPolyline = MapPerformance.maxStopsFullPolyline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      rotaProvider.select(
        (s) => (
          routeMapParadasStamp(s.paradas),
          s.rota?.id,
          s.rota?.otimizada ?? false,
          s.routePoints.length,
          s.navigationLegPoints.length,
          s.navigationTargetParadaId,
          s.driverPosition?.latitude,
          s.driverPosition?.longitude,
          s.driverHeading,
        ),
      ),
    );
    final state = ref.read(rotaProvider);
    final paradas = state.paradas;
    final routeOptimized = state.rota?.otimizada == true;
    final navigationLegPoints = state.navigationLegPoints;
    final navigationTargetParadaId = state.navigationTargetParadaId;
    final driverPosition = state.driverPosition;

    final isPro = ref.watch(subscriptionProvider.select((s) => s.isPro));
    final basemapSetting = ref.watch(mapSettingsProvider.select((s) => s.basemap));

    final n = paradas.length;
    final heavy = n > MapPerformance.heavyStopCount;
    var basemap = MapBasemap.effectiveForPlan(basemapSetting, isPro: isPro);
    if (heavy &&
        basemap != MapBasemap.dark &&
        (basemap.labelOverlays?.length ?? 0) > 1) {
      basemap = MapBasemap.streets;
    }
    final showOsrmRoute = isPro && routeOptimized;
    final navTargetId = selectedParadaId ?? navigationTargetParadaId;
    final leg = navigationLegPoints;
    final showLegToTarget =
        showOsrmRoute && navTargetId != null && leg.length >= 2;

    return RepaintBoundary(
      child: RouteMap(
        key: ValueKey<String>('${state.rota?.id ?? 0}_${basemap.name}'),
        paradas: paradas,
        fastTileLayer: heavy,
        networkTilesOnly: heavy,
        lightweightMarkers: heavy,
        routePoints: const <LatLng>[],
        navigationLegPoints: showLegToTarget ? leg : const <LatLng>[],
        legRouteOnly: showLegToTarget,
        allowRoutePolylines: showLegToTarget,
        driverPosition: driverPosition,
        highlightStop: null,
        selectedParadaId: navTargetId,
        rotaMapController: rotaMapController,
        onParadaTap: onParadaTap,
        basemap: basemap,
        hideCompletedStops: false,
        showStopCallouts: false,
        viewportClusters: viewportClusters,
        pinIconStyles: pinIconStyles,
        onCameraMove: onCameraMove,
        onCameraIdle: onCameraIdle,
      ),
    );
  }
}
