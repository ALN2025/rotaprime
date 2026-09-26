import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/rota.dart';
import 'package:rota_prime/services/map_tile_prefetch.dart';
import 'package:rota_prime/widgets/driver_route_top_bar.dart';
import 'package:rota_prime/widgets/pro_gate.dart';
import 'package:rota_prime/widgets/route_planning_action_bar.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/screens/finalizar_rota_screen.dart';
import 'package:rota_prime/screens/route_delivery_ledger_screen.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/providers/app_shell_provider.dart';
import 'package:rota_prime/services/delivery_cockpit_service.dart';
import 'package:rota_prime/services/location_service.dart';
import 'package:rota_prime/widgets/delivery_cockpit_overlay.dart';
import 'package:rota_prime/widgets/delivery_run_menu_sheet.dart';
import 'package:rota_prime/widgets/map_layers_sheet.dart';
import 'package:rota_prime/widgets/stop_action_panel.dart';
import 'package:rota_prime/widgets/route_map.dart';
import 'package:rota_prime/widgets/spoke_widgets.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/utils/parada_packages.dart';
import 'package:rota_prime/utils/stop_route_order.dart';
import 'package:rota_prime/utils/map_screen_layout.dart';
import 'package:rota_prime/utils/route_delivery_stats.dart';
import 'package:rota_prime/utils/navigation_parada_utils.dart';
import 'package:rota_prime/widgets/circuit_active_stop_list.dart';
import 'package:rota_prime/widgets/delivery_map_legend.dart';
import 'package:rota_prime/widgets/circuit_view_toggle.dart';
import 'package:rota_prime/widgets/add_parada_sheet.dart';

class RotaAtivaScreen extends ConsumerStatefulWidget {
  const RotaAtivaScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<RotaAtivaScreen> createState() => _RotaAtivaScreenState();
}

class _RotaAtivaScreenState extends ConsumerState<RotaAtivaScreen>
    with WidgetsBindingObserver {
  /// Mapa já montado nesta sessão — evita recarregar tudo ao voltar do Waze.
  static int? _mapSessionRotaId;

  static const _distance = Distance();

  final _mapController = MapController();
  final _stopDockMeasureKey = GlobalKey();
  static const _stopDockCollapsedHeight = 40.0;
  bool _stopDockExpanded = false;
  double _stopDockExpandedHeight = 300;
  int? _lastDockMeasureStopId;
  final _location = LocationService();
  StreamSubscription<DriverFix>? _gpsSub;
  int? _selectedParadaId;
  bool _drivingMode = true;
  bool _followGps = true;
  /// Rotação automática com a direção do carro (desliga ao girar o mapa com dois dedos).
  bool _followHeading = true;
  /// Mapa parado no pin — GPS não arrasta a câmera (entrega ativa).
  bool _mapLocked = false;
  static const _driveZoom = 17.5;
  Timer? _legRefreshDebounce;
  bool _mapPrimed = false;
  CircuitDeliveryView _view = CircuitDeliveryView.map;
  /// Usuário escolheu um pin no mapa — não trocar alvo automaticamente até recentralizar GPS.
  bool _manualTargetLock = false;
  LatLng? _liveDriverPosition;
  double _liveDriverHeading = 0;
  Timer? _providerDriverSync;
  Timer? _routeClockTimer;
  bool _optimized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final rota = ref.read(rotaProvider).rota;
    final status = rota?.status;
    final rotaId = ref.read(rotaProvider).rotaId;
    if (status == RotaStatus.finalizada) {
      _view = CircuitDeliveryView.list;
      _mapPrimed = true;
      _mapSessionRotaId = rotaId;
      _optimized = rota?.otimizada == true;
      _followGps = false;
      _followHeading = false;
      _drivingMode = false;
    } else if (status == RotaStatus.rascunho) {
      _mapPrimed = true;
      _mapSessionRotaId = rotaId;
      _followGps = false;
      _followHeading = false;
      _drivingMode = false;
      _optimized = rota?.otimizada == true;
    }
    _routeClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (rotaId != null && _mapSessionRotaId == rotaId && status == RotaStatus.ativa) {
        await _restoreMapSession();
        return;
      }
      if (status == RotaStatus.finalizada) {
        unawaited(ref.read(rotaProvider.notifier).stripRouteTraceUnlessProOptimized());
        return;
      }
      if (status == RotaStatus.rascunho) {
        if (!ref.read(subscriptionProvider).isPro &&
            ref.read(rotaProvider).paradas.isNotEmpty) {
          unawaited(ref.read(rotaProvider.notifier).applySpreadsheetOrderOnly(force: false));
        }
        unawaited(ref.read(rotaProvider.notifier).stripRouteTraceUnlessProOptimized());
        return;
      }
      await _coldStartMapSession();
    });
  }

  /// Rota finalizada: só consulta (sem GPS, OSRM nem cockpit de entrega).
  Future<void> _bootstrapPlanningRouteView() async {
    final rota = ref.read(rotaProvider).rota;
    final isPro = ref.read(subscriptionProvider).isPro;
    if (!isPro && ref.read(rotaProvider).paradas.isNotEmpty) {
      await ref.read(rotaProvider.notifier).applySpreadsheetOrderOnly(force: false);
    } else if (isPro && rota?.otimizada == true) {
      if (mounted) setState(() => _optimized = true);
    }
    if (mounted) {
      setState(() {
        _mapPrimed = true;
        _followGps = false;
        _followHeading = false;
        _drivingMode = false;
      });
    }
    _mapSessionRotaId = ref.read(rotaProvider).rotaId;
    await ref.read(rotaProvider.notifier).stripRouteTraceUnlessProOptimized();
  }

  Future<void> _bootstrapFinalizedRouteView() async {
    final rota = ref.read(rotaProvider).rota;
    if (mounted) {
      setState(() {
        _mapPrimed = true;
        _optimized = rota?.otimizada == true;
        _view = CircuitDeliveryView.list;
        _followGps = false;
        _followHeading = false;
        _drivingMode = false;
      });
    }
    _mapSessionRotaId = ref.read(rotaProvider).rotaId;
    await ref.read(rotaProvider.notifier).stripRouteTraceUnlessProOptimized();
  }

  Future<void> _restoreMapSession() async {
    final status = ref.read(rotaProvider).rota?.status;
    if (status == RotaStatus.finalizada) {
      await _bootstrapFinalizedRouteView();
      return;
    }
    if (status == RotaStatus.rascunho) {
      await _bootstrapPlanningRouteView();
      return;
    }
    final st0 = ref.read(rotaProvider);
    _liveDriverPosition = st0.driverPosition;
    _liveDriverHeading = st0.driverHeading;
    _optimized = true;
    if (mounted) {
      setState(() => _mapPrimed = true);
    }
    await DeliveryCockpitService.instance.start();
    await DeliveryCockpitService.instance.wakeForInteraction();
    _startGpsFollow();
    unawaited(_softResumeFromBackground());
  }

  Future<void> _coldStartMapSession() async {
    final rota = ref.read(rotaProvider).rota;
    final isPro = ref.read(subscriptionProvider).isPro;
    if (isPro && rota?.otimizada == true) {
      if (mounted) setState(() => _optimized = true);
    } else if (!isPro && ref.read(rotaProvider).paradas.isNotEmpty) {
      await ref.read(rotaProvider.notifier).applySpreadsheetOrderOnly(force: false);
      if (mounted) setState(() => _optimized = true);
    }
    await DeliveryCockpitService.instance.start();
    if (mounted) setState(() {});
    await ref.read(rotaProvider.notifier).stripRouteTraceUnlessProOptimized();
    await _primeMapView();
    if (!mounted) return;
    setState(() => _mapPrimed = true);
    await ref.read(rotaProvider.notifier).refreshDriverLocation();
    final st0 = ref.read(rotaProvider);
    _liveDriverPosition = st0.driverPosition;
    _liveDriverHeading = st0.driverHeading;
    final nav = ref.read(rotaProvider.notifier);
    await nav.syncActiveNavigationTarget();
    await nav.refreshNavigationLegForActiveTarget(force: true);
    final active = RotaNotifier.activeNavigationParadaFrom(
      ref.read(rotaProvider),
      isPro: ref.read(subscriptionProvider).isPro,
    );
    if (active != null && mounted) {
      setState(() => _selectedParadaId = active.id);
    }
    _mapSessionRotaId = ref.read(rotaProvider).rotaId;
    _startGpsFollow();
  }

  Future<void> _softResumeFromBackground() async {
    if (!_mapPrimed || !mounted) return;
    await ref.read(rotaProvider.notifier).refreshDriverLocation();
    if (!mounted) return;
    final st = ref.read(rotaProvider);
    _liveDriverPosition = st.driverPosition;
    _liveDriverHeading = st.driverHeading;
    if (mounted) setState(() {});
    final nav = ref.read(rotaProvider.notifier);
    unawaited(nav.refreshNavigationLegForActiveTarget());
  }

  Future<void> _exitToPlanning() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        title: const Text('Parar de entregar agora?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Você volta para ajustar a rota. Para encerrar o dia, use "Terminei as entregas" no menu.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, voltar', style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DeliveryCockpitService.instance.stop();
    await ref.read(rotaProvider.notifier).returnToPlanningFromActive();
    if (!mounted) return;
    navigateToRouteMap(context, ref);
  }

  double _stopDockOccupiedHeight() => _liveStopDockHeightPx();

  /// Altura real da aba (medida no layout) — evita subestimar ao focar o pin.
  double _liveStopDockHeightPx() {
    if (!_stopDockExpanded) return _stopDockCollapsedHeight;
    final box =
        _stopDockMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.height > 60) {
      return box.size.height;
    }
    final h = MediaQuery.sizeOf(context).height;
    return math.max(_stopDockExpandedHeight, h * 0.38);
  }

  double _mapTopOverlayHeight() => driverRouteTopChromeHeight(context);

  void _scheduleStopDockMeasure(int? stopId) {
    if (stopId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureStopDock(stopId);
    });
  }

  void _measureStopDock(int stopId) {
    if (!_stopDockExpanded) return;
    final box =
        _stopDockMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      _scheduleStopDockMeasure(stopId);
      return;
    }
    final h = box.size.height;
    if (h > 80 && (h - _stopDockExpandedHeight).abs() > 2) {
      setState(() => _stopDockExpandedHeight = h);
    }
    final sel = _selectedParadaId;
    if (sel == stopId && !_mapLocked) {
      for (final p in ref.read(rotaProvider).paradas) {
        if (p.id == sel) {
          _scheduleMapFocusOnParada(p);
          break;
        }
      }
    }
  }

  void _toggleStopDock({Parada? refocus}) {
    setState(() => _stopDockExpanded = !_stopDockExpanded);
    if (_stopDockExpanded && !_mapLocked) {
      final stop = refocus ??
          _focusedStop(ref.read(rotaProvider), ref.read(rotaProvider).paradas);
      if (stop != null) {
        _scheduleStopDockMeasure(stop.id);
        _scheduleMapFocusOnParada(stop);
      }
    } else if (_stopDockExpanded && refocus != null) {
      _scheduleStopDockMeasure(refocus.id);
    }
  }

  void _openFinalizarRota() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FinalizarRotaScreen()),
    );
  }

  void _openDeliveryMenu() {
    final isPro = ref.read(subscriptionProvider).isPro;
    showDeliveryRunMenuSheet(
      context,
      ref,
      onExitToPlanning: _exitToPlanning,
      onReoptimize: isPro ? _otimizar : null,
      onOpenDeliveryLedger: _openDeliveryLedger,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(DeliveryCockpitService.instance.start());
      unawaited(DeliveryCockpitService.instance.wakeForInteraction());
      if (_mapPrimed) {
        _startGpsFollow();
        unawaited(_softResumeFromBackground());
      }
    }
  }

  Future<void> _primeMapView() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final state = ref.read(rotaProvider);
    final current = RotaNotifier.activeNavigationParadaFrom(
      state,
      isPro: ref.read(subscriptionProvider).isPro,
    );
    if (current?.latitude != null && current?.longitude != null) {
      _centerMapOnParada(current!, zoom: 15);
      _mapController.rotate(0);
      return;
    }

    final points = <LatLng>[];
    for (final p in state.paradas) {
      if (p.latitude != null && p.longitude != null) {
        points.add(LatLng(p.latitude!, p.longitude!));
      }
    }
    if (points.isEmpty) {
      points.addAll(state.routePoints);
    }
    if (points.isEmpty) return;

    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(48, 100, 48, 280),
          maxZoom: 16,
        ),
      );
    } else {
      _mapController.move(points.first, 15);
    }
    _mapController.rotate(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsSub?.cancel();
    _providerDriverSync?.cancel();
    _legRefreshDebounce?.cancel();
    _routeClockTimer?.cancel();
    super.dispose();
  }

  Future<void> _useImportOrder() async {
    await ref.read(rotaProvider.notifier).applySpreadsheetOrderOnly();
    if (!mounted) return;
    setState(() => _optimized = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ordem do romaneio — sequência da planilha'),
      ),
    );
  }

  Future<void> _otimizar() async {
    if (!mounted) return;
    if (!await ensureProOrPrompt(context, ref, feature: 'Otimização de rota')) return;
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final st = ref.watch(rotaProvider);
          return OptimizingRouteDialog(
            statusMessage: st.statusMessage,
            progress: st.optimizeProgress,
          );
        },
      ),
    );
    try {
      await ref.read(rotaProvider.notifier).optimizeRoute(
            isPro: ref.read(subscriptionProvider).isPro,
          );
      if (!mounted) return;
      setState(() => _optimized = true);
    } catch (_) {
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _startRoute() async {
    final isPro = ref.read(subscriptionProvider).isPro;
    if (!isPro) {
      await ref.read(rotaProvider.notifier).applySpreadsheetOrderOnly();
      await ref.read(rotaProvider.notifier).stripRouteTraceUnlessProOptimized();
    }
    final st = ref.read(rotaProvider);
    await ref.read(rotaProvider.notifier).confirmRoute();
    MapTilePrefetch.prefetchAllBasemapsForRoute(
      paradas: st.paradas,
      onProgress: (msg) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _manualTargetLock = true;
      _followGps = false;
      _followHeading = false;
    });
    final isProAfter = ref.read(subscriptionProvider).isPro;
    final first = RotaNotifier.activeNavigationParadaFrom(
      ref.read(rotaProvider),
      isPro: isProAfter,
    );
    if (first != null) {
      setState(() => _selectedParadaId = first.id);
      unawaited(
        ref.read(rotaProvider.notifier).selectNavigationTarget(first.id),
      );
      _scheduleMapFocusOnParada(first, settleCamera: true);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rota iniciada. Toque no cadeado para travar o mapa no alvo, ou no GPS para seguir você.'),
      ),
    );
  }

  Widget _buildTopBar({
    required CircuitDeliveryView view,
    required ValueChanged<CircuitDeliveryView> onViewChanged,
    required int packagesDone,
    required int packagesTotal,
    required bool routeActive,
    required DateTime? routeActiveSince,
    required int estimatedMinutes,
    required bool allowManualAdd,
    bool compactHeader = true,
  }) {
    return SafeArea(
      bottom: false,
      child: DriverRouteTopBar(
        view: view,
        onViewChanged: onViewChanged,
        onMenu: _openDeliveryMenu,
        packagesDone: packagesDone,
        packagesTotal: packagesTotal,
        routeActive: routeActive,
        routeActiveSince: routeActiveSince,
        estimatedMinutes: estimatedMinutes,
        onAddParada: allowManualAdd ? _addParadaToRoute : null,
        showPlanBadge: widget.embeddedInShell,
        compactHeader: compactHeader,
      ),
    );
  }

  void _openDeliveryLedger() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RouteDeliveryLedgerScreen(
          onOpenOnMap: (p) {
            Navigator.of(context).pop();
            setState(() => _view = CircuitDeliveryView.map);
            _openParada(p, focusMapOnPin: true);
          },
        ),
      ),
    );
  }

  Future<void> _focusNextPendingAfterReview() async {
    final paradas = ref.read(rotaProvider).paradas;
    final next = RotaNotifier.nextPendingParada(paradas);
    if (next == null) {
      setState(() => _selectedParadaId = null);
      return;
    }
    await _openParada(next);
  }

  Widget _wrapShellPop(Widget child) {
    if (widget.embeddedInShell) {
      return ColoredBox(color: AppColors.background, child: child);
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
        }
      },
      child: child,
    );
  }

  void _expandStopSheet({bool immediate = false, int? stopId}) {
    if (!_stopDockExpanded) {
      setState(() => _stopDockExpanded = true);
    }
    if (stopId != null) {
      _lastDockMeasureStopId = stopId;
      _scheduleStopDockMeasure(stopId);
    }
  }

  Future<void> _startGpsFollow() async {
    await _gpsSub?.cancel();
    if (!_drivingMode) return;
    _gpsSub = _location.watchDriver().listen((fix) {
      if (!mounted || !_mapPrimed) return;
      _liveDriverPosition = fix.position;
      _liveDriverHeading = fix.headingDegrees;
      setState(() {});
      _syncNavigationCamera(fix.position, fix.headingDegrees);
      _providerDriverSync?.cancel();
      _providerDriverSync = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        ref.read(rotaProvider.notifier).updateDriverLive(
              fix.position,
              headingDegrees: fix.headingDegrees,
            );
      });
      _legRefreshDebounce?.cancel();
      _legRefreshDebounce = Timer(const Duration(milliseconds: 650), () async {
        if (!mounted) return;
        final notifier = ref.read(rotaProvider.notifier);
        if (_manualTargetLock) {
          await notifier.refreshNavigationLegForActiveTarget();
        } else {
          await notifier.syncActiveNavigationTarget();
          await notifier.refreshNavigationLegForActiveTarget();
        }
        if (!mounted) return;
        final st = ref.read(rotaProvider);
        final isPro = ref.read(subscriptionProvider).isPro;
        final target = RotaNotifier.activeNavigationParadaFrom(st, isPro: isPro);
        if (!_mapLocked && !_manualTargetLock) {
          setState(() {
            if (target != null && !target.entregue && !target.falha) {
              _selectedParadaId = target.id;
            }
          });
        }
      });
    });
  }

  void _syncNavigationCamera(LatLng pos, double heading) {
    final h = MediaQuery.of(context).size.height;
    if (_followGps && !_mapLocked) {
      _mapController.move(
        pos,
        _driveZoom,
        offset: Offset(0, h * 0.22),
      );
    }
    if (_followHeading && _drivingMode) {
      _mapController.rotate(-heading);
    }
  }

  void _onUserMapGesture() {
    setState(() {
      _followGps = false;
      _followHeading = false;
    });
  }

  void _centerMapOnParada(
    Parada p, {
    double zoom = 16.5,
  }) {
    if (p.latitude == null || p.longitude == null) return;
    final mq = MediaQuery.of(context);
    final h = mq.size.height;
    final top = _mapTopOverlayHeight();
    final dock = _liveStopDockHeightPx();
    const pinTipPad = 48.0;
    final visible = (h - top - dock - pinTipPad).clamp(140.0, h);
    // Centro da faixa do mapa acima da aba (flutter_map: offset Y negativo = pin sobe na tela).
    final pinY = top + visible * 0.38;
    final offsetY = (pinY - h * 0.5).clamp(-h * 0.46, h * 0.12);
    _mapController.move(
      LatLng(p.latitude!, p.longitude!),
      zoom,
      offset: Offset(0, offsetY),
    );
  }

  /// Enquadra automaticamente GPS + pin + tarja laranja (perto ou longe).
  void _fitOrCenterOnSelectedParada(Parada p) {
    final pin = latLngForParada(p);
    if (pin == null) return;

    final driver = _liveDriverPosition ?? ref.read(rotaProvider).driverPosition;
    final points = <LatLng>[pin];
    if (driver != null) points.add(driver);
    final leg = ref.read(rotaProvider).navigationLegPoints;
    if (leg.length >= 2) points.addAll(leg);

    final top = _mapTopOverlayHeight();
    final dock = _liveStopDockHeightPx();
    final padding = EdgeInsets.fromLTRB(36, top + 20, 36, dock + 52);

    if (points.length == 1) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: _paddedBoundsAround(pin, radiusMeters: 120),
          padding: padding,
          maxZoom: 17,
        ),
      );
    } else {
      var bounds = LatLngBounds.fromPoints(points);
      if (driver != null) {
        final spanMeters = _distance.as(LengthUnit.Meter, bounds.southWest, bounds.northEast);
        if (spanMeters < 80) {
          bounds = _paddedBoundsAround(pin, radiusMeters: 140);
        }
      }
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: padding,
          maxZoom: 17.5,
        ),
      );
    }

    if (_followHeading) {
      _mapController.rotate(-_liveDriverHeading);
    } else {
      _mapController.rotate(0);
    }
  }

  LatLngBounds _paddedBoundsAround(LatLng center, {required double radiusMeters}) {
    const earthRadiusM = 6378137.0;
    final dLat = (radiusMeters / earthRadiusM) * (180 / math.pi);
    final dLng = dLat / math.cos(center.latitude * math.pi / 180);
    return LatLngBounds(
      LatLng(center.latitude - dLat, center.longitude - dLng),
      LatLng(center.latitude + dLat, center.longitude + dLng),
    );
  }

  void _scheduleMapFocusOnParada(Parada p, {bool settleCamera = false}) {
    void focus() {
      if (!mounted) return;
      _fitOrCenterOnSelectedParada(p);
    }

    focus();
    WidgetsBinding.instance.addPostFrameCallback((_) => focus());
    if (_mapLocked && !settleCamera) return;
    if (!settleCamera) {
      for (final ms in const [200, 450]) {
        Future<void>.delayed(Duration(milliseconds: ms), focus);
      }
      return;
    }
    for (final ms in const [80, 200, 400, 650, 950]) {
      Future<void>.delayed(Duration(milliseconds: ms), focus);
    }
  }

  Future<void> _focusNextDelivery(Parada next, {Parada? afterDelivered}) async {
    setState(() {
      _selectedParadaId = next.id;
      _manualTargetLock = false;
    });
    if (!next.entregue && !next.falha) {
      await ref.read(rotaProvider.notifier).selectNavigationTarget(next.id);
    }
    if (!mounted) return;
    _expandStopSheet(stopId: next.id);
    _scheduleMapFocusOnParada(next);
    if (afterDelivered != null && sameDeliveryStop(afterDelivered, next)) {
      _notifySameStopRemainingPackage(next);
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }

  void _notifySameStopRemainingPackage(Parada next) {
    final msg = ParadaLabels.sameStopNextPackageNotice(
      ref.read(rotaProvider).paradas,
      next,
    );
    if (msg.isEmpty) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.inventory_2, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mais pacote neste endereço',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _skipToNextFocus(Parada next) async {
    await _openParada(next);
  }

  Future<void> _markEntregueOk(Parada current) async {
    await _completeDelivery(current);
  }

  Future<void> _completeDelivery(Parada delivered) async {
    final next = await ref.read(rotaProvider.notifier).markEntregue(
          delivered.id,
          entregue: true,
          falha: false,
        );
    if (!mounted) return;
    if (next != null) {
      await _focusNextDelivery(next, afterDelivered: delivered);
    } else {
      setState(() => _selectedParadaId = null);
    }
  }

  Future<void> _failDelivery(Parada p) async {
    final next = await ref.read(rotaProvider.notifier).markEntregue(
          p.id,
          entregue: false,
          falha: true,
        );
    if (!mounted) return;
    if (next != null) await _focusNextDelivery(next, afterDelivered: p);
  }

  Future<void> _addParadaToRoute() async {
    final added = await openManualParadaFlow(context, ref);
    if (!mounted || added == null) return;
    unawaited(_openParada(added));
    final isPro = ref.read(subscriptionProvider).isPro;
    final optimized = ref.read(rotaProvider).rota?.otimizada == true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Entrega adicionada à rota'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.card,
          action: isPro && optimized
              ? SnackBarAction(
                  label: 'Reotimizar',
                  textColor: AppColors.orange,
                  onPressed: () {
                    ref.read(rotaProvider.notifier).optimizeRoute(isPro: true);
                  },
                )
              : null,
        ),
      );
  }

  Future<void> _openParada(Parada p, {bool focusMapOnPin = true}) async {
    setState(() {
      _selectedParadaId = p.id;
      _manualTargetLock = true;
      _followGps = false;
      _followHeading = false;
    });
    _expandStopSheet(immediate: true, stopId: p.id);
    if (focusMapOnPin) {
      _fitOrCenterOnSelectedParada(p);
    }
    if (!p.entregue && !p.falha) {
      await ref.read(rotaProvider.notifier).selectNavigationTarget(p.id);
    }
    if (!mounted || !focusMapOnPin) return;
    _fitOrCenterOnSelectedParada(p);
    _scheduleMapFocusOnParada(p);
  }

  void _resetMapNorth() {
    setState(() => _followHeading = false);
    _mapController.rotate(0);
  }

  Parada? _focusedStop(RotaState state, List<Parada> paradas) {
    final sel = _selectedParadaId;
    if (sel != null) {
      for (final p in paradas) {
        if (p.id == sel) return p;
      }
    }
    return RotaNotifier.activeNavigationParadaFrom(
          state,
          isPro: ref.read(subscriptionProvider).isPro,
        ) ??
        RotaNotifier.nextPendingParada(paradas);
  }

  Future<void> _syncLegToFocusedStop(Parada p) async {
    if (p.entregue || p.falha) return;
    await ref.read(rotaProvider.notifier).selectNavigationTarget(p.id);
    if (mounted) _fitOrCenterOnSelectedParada(p);
  }

  void _toggleMapLock() {
    final wasLocked = _mapLocked;
    setState(() {
      _mapLocked = !wasLocked;
      if (_mapLocked) {
        _followGps = false;
        _followHeading = false;
      }
    });

    final messenger = ScaffoldMessenger.of(context);
    if (_mapLocked && !wasLocked) {
      final current = _focusedStop(ref.read(rotaProvider), ref.read(rotaProvider).paradas);
      if (current != null) {
        unawaited(_syncLegToFocusedStop(current));
      }
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Mapa travado: não arraste nem dê zoom. GPS e linha laranja até a parada em foco seguem atualizando. Toque outro pin ou abra o cadeado.',
          ),
        ),
      );
    } else if (!_mapLocked && wasLocked) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Mapa livre: arraste com o dedo. Toque no GPS para a câmera seguir você.',
          ),
        ),
      );
    }
  }

  void _recenterGps() {
    setState(() {
      _mapLocked = false;
      _followGps = true;
      _followHeading = _drivingMode;
      _manualTargetLock = false;
    });
    final pos = ref.read(rotaProvider).driverPosition;
    final heading = ref.read(rotaProvider).driverHeading;
    if (pos == null) {
      ref.read(rotaProvider.notifier).refreshDriverLocation();
      return;
    }
    if (_drivingMode) {
      _syncNavigationCamera(pos, heading);
    } else {
      _mapController.move(pos, 16);
    }
    final nav = ref.read(rotaProvider.notifier);
    nav.syncActiveNavigationTarget().then((_) {
      if (mounted) nav.refreshNavigationLegForActiveTarget(force: true);
    });
  }

  void _consumeMapFocusRequest(int focusId) {
    ref.read(mapFocusParadaIdProvider.notifier).state = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      for (final p in ref.read(rotaProvider).paradas) {
        if (p.id == focusId) {
          setState(() => _view = CircuitDeliveryView.map);
          await _openParada(p, focusMapOnPin: true);
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(mapFocusParadaIdProvider, (prev, focusId) {
      if (focusId != null) _consumeMapFocusRequest(focusId);
    });

    final state = ref.watch(rotaProvider);
    final isPro = ref.watch(subscriptionProvider).isPro;
    final routeOptimized = state.rota?.otimizada == true;
    final showFullRouteTrace = isPro && routeOptimized;
    var basemap = ref.watch(mapSettingsProvider).basemap;
    final paradas = state.paradas;
    final allowManualAdd = state.allowManualParadaEntry;
    final imported = state.rota?.pacotesImportados ?? 0;
    final packagesTotal = RouteDeliveryStats.packageDenominator(
      paradas,
      importedTotal: imported > 0 ? imported : null,
    );
    final packagesDone = RouteDeliveryStats.finishedPackages(paradas);
    final rota = state.rota;
    final routeActive = rota?.status == RotaStatus.ativa;
    final estimatedMinutes = rota?.duracaoMinutos ?? 0;
    final dur = rota?.duracaoMinutos ?? 0;
    final durationPlanningLabel = dur > 0
        ? '${dur ~/ 60}h ${(dur % 60).toString().padLeft(2, '0')}min'
        : 'Planilha';
    final allDeliveriesFinished = RouteDeliveryStats.allDeliveriesFinished(paradas);
    final isFinalized = rota?.status == RotaStatus.finalizada;
    final showPlanningBar = rota != null && rota.status == RotaStatus.rascunho;
    final showPlanningBarOnList =
        showPlanningBar && !allDeliveriesFinished;
    final current = _focusedStop(state, paradas);
    final previousStop = current != null ? RotaNotifier.previousInRouteOrder(paradas, current) : null;
    final nextInRoute = current != null
        ? RotaNotifier.nextPendingInRouteOrderAfter(paradas, current)
        : null;
    final multiStopsOnMap = paradas.length > 1;
    final pinRouteFocus = _manualTargetLock && _selectedParadaId != null;
    final showFullOptimizedPolyline =
        showFullRouteTrace && !routeActive && !pinRouteFocus;
    final showNavLegPolyline =
        isPro && (routeActive || pinRouteFocus);

    if (_view == CircuitDeliveryView.list) {
      final listBody = Scaffold(
          backgroundColor: AppColors.background,
          body: DeliveryCockpitOverlay(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(
                    view: _view,
                    onViewChanged: (v) => setState(() => _view = v),
                    packagesDone: packagesDone,
                    packagesTotal: packagesTotal,
                    routeActive: routeActive,
                    routeActiveSince: state.routeActiveSince,
                    estimatedMinutes: estimatedMinutes,
                    allowManualAdd: allowManualAdd,
                  ),
                  Expanded(
                    child: CircuitActiveStopList(
                      paradas: paradas,
                      activeParadaId: current?.id,
                      driverPosition: state.driverPosition,
                      listModeAllDone: allDeliveriesFinished,
                      onTapStop: (p) {
                        setState(() => _view = CircuitDeliveryView.map);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _openParada(p, focusMapOnPin: true);
                        });
                      },
                      onDelivered: _completeDelivery,
                      onFailed: _failDelivery,
                    ),
                  ),
                  if (isFinalized)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Rota finalizada — consulta entregues e endereços na lista ou no mapa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (allDeliveriesFinished && !isFinalized) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: ElevatedButton.icon(
                        onPressed: _openFinalizarRota,
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text(
                          'Terminei as entregas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        MediaQuery.paddingOf(context).bottom + 10,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () => switchAppShellTab(ref, 1),
                        icon: const Icon(Icons.route_outlined, color: AppColors.orange),
                        label: const Text(
                          'Ver rotas finalizadas',
                          style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ] else ...[
                    if (showPlanningBarOnList)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: RoutePlanningActionBar(
                          optimized: _optimized,
                          isPro: isPro,
                          onOptimize: _otimizar,
                          onUseImportOrder: _useImportOrder,
                          onStart: _startRoute,
                          onRefine: _otimizar,
                          durationLabel: durationPlanningLabel,
                        ),
                      ),
                    if (routeActive)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          MediaQuery.paddingOf(context).bottom + 10,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _openFinalizarRota,
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text(
                            'Terminei as entregas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(height: MediaQuery.paddingOf(context).bottom + 10),
                  ],
                ],
              ),
            ),
          );
      return _wrapShellPop(listBody);
    }

    final mapBody = Scaffold(
      backgroundColor: AppColors.background,
      body: DeliveryCockpitOverlay(
        child: Stack(
        children: [
          Positioned.fill(
            child: RouteMap(
              paradas: paradas,
              interactive: !_mapLocked,
              routePoints:
                  showFullOptimizedPolyline ? state.routePoints : const [],
              navigationLegPoints: showNavLegPolyline
                  ? state.navigationLegPoints
                  : const [],
              allowRoutePolylines:
                  showFullOptimizedPolyline || showNavLegPolyline,
              driverPosition: _liveDriverPosition ?? state.driverPosition,
              driverHeading: _liveDriverPosition != null
                  ? _liveDriverHeading
                  : state.driverHeading,
              navigationView: _drivingMode,
              legRouteOnly: true,
              mapRotationDegrees: 0,
              selectedParadaId: _manualTargetLock
                  ? (_selectedParadaId ?? current?.id)
                  : (current?.id ?? _selectedParadaId),
              mapController: _mapController,
              onParadaTap: (p) => _openParada(p, focusMapOnPin: true),
              onUserMapGesture: _onUserMapGesture,
              basemap: basemap,
              initialZoom: 15,
              showStopCallouts: false,
              fastTileLayer: true,
              hideCompletedStops: false,
            ),
          ),
          Positioned(
            right: 12,
            bottom: _stopDockOccupiedHeight() + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (routeActive) ...[
                  MapCircleButton(
                    icon: _mapLocked ? Icons.lock : Icons.lock_open_outlined,
                    onTap: _toggleMapLock,
                  ),
                  const SizedBox(height: 10),
                ],
                const DeliveryMapLegend(),
                const SizedBox(height: 10),
                MapCircleButton(
                  icon: Icons.layers_outlined,
                  onTap: () => showMapLayersSheet(context, ref),
                ),
                const SizedBox(height: 8),
                MapCircleButton(
                  icon: Icons.explore_outlined,
                  onTap: _resetMapNorth,
                ),
                const SizedBox(height: 8),
                MapCircleButton(
                  icon: (_followGps && _followHeading && !_mapLocked)
                      ? Icons.gps_fixed
                      : Icons.gps_not_fixed,
                  onTap: _recenterGps,
                ),
              ],
            ),
          ),
          _buildTopBar(
            view: _view,
            onViewChanged: (v) => setState(() => _view = v),
            packagesDone: packagesDone,
            packagesTotal: packagesTotal,
            routeActive: routeActive,
            routeActiveSince: state.routeActiveSince,
            estimatedMinutes: estimatedMinutes,
            allowManualAdd: allowManualAdd,
          ),
          if (showPlanningBar)
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 8,
              child: Material(
                color: AppColors.sheet,
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: RoutePlanningActionBar(
                    optimized: _optimized,
                    isPro: isPro,
                    onOptimize: _otimizar,
                    onUseImportOrder: _useImportOrder,
                    onStart: _startRoute,
                    onRefine: _otimizar,
                    durationLabel: durationPlanningLabel,
                  ),
                ),
              ),
            ),
          if (current != null && routeActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActiveStopDock(
                stop: current,
                paradas: paradas,
                reviewDone: current.entregue || current.falha,
                multiStopsOnMap: multiStopsOnMap,
                previousStop: previousStop,
                nextInRoute: nextInRoute,
              ),
            ),
        ],
        ),
      ),
    );
    return _wrapShellPop(mapBody);
  }

  Widget _buildActiveStopDock({
    required Parada stop,
    required List<Parada> paradas,
    required bool reviewDone,
    required bool multiStopsOnMap,
    required Parada? previousStop,
    required Parada? nextInRoute,
  }) {
    if (_lastDockMeasureStopId != stop.id) {
      _lastDockMeasureStopId = stop.id;
      _scheduleStopDockMeasure(stop.id);
    }

    final actionPanel = reviewDone
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ParadaLabels.deliveryReferenceLine(stop),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stop.entregue ? 'Status: entregue' : 'Status: não entregue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              StopAddressPeekCard(
                peek: StopRouteAddressPeek.fromParadas(
                  paradas,
                  stop,
                  next: multiStopsOnMap ? nextInRoute : null,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _openDeliveryLedger,
                  icon: const Icon(Icons.fact_check_outlined, size: 20),
                  label: const Text(
                    'Entregues e não entregues',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  style: primaryOrangeButtonStyle(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _focusNextPendingAfterReview,
                child: const Text('Ir para próxima pendente'),
              ),
            ],
          )
        : StopActionPanel(
            routePeek: StopRouteAddressPeek.fromParadas(
              paradas,
              stop,
              next: multiStopsOnMap ? nextInRoute : null,
            ),
            onPrevious: !multiStopsOnMap || previousStop == null
                ? null
                : () => _skipToNextFocus(previousStop),
            onNext: !multiStopsOnMap || nextInRoute == null
                ? null
                : () => _skipToNextFocus(nextInRoute),
            onFailed: () => _failDelivery(stop),
            onDelivered: () => _markEntregueOk(stop),
          );

    final dockBody = Material(
      color: AppColors.sheet,
      elevation: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        key: _stopDockExpanded ? _stopDockMeasureKey : null,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleStopDock(refocus: stop),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_stopDockExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Toque · ver entrega',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SheetDragHandle(
                  sheetController: null,
                  emphasized: true,
                ),
              ],
            ),
          ),
          if (_stopDockExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: actionPanel,
            )
          else
            const SizedBox(height: 0),
        ],
      ),
    );

    if (!_stopDockExpanded) {
      return SizedBox(
        height: _stopDockCollapsedHeight,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: dockBody,
          ),
        ),
      );
    }

    return dockBody;
  }

}
