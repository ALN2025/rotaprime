import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/models/rota.dart';
import 'package:rota_prime/widgets/delivery_dock_peek_bar.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/providers/app_shell_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:intl/intl.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/screens/conta_rotas_screen.dart';
import 'package:rota_prime/screens/file_picker_screen.dart';
import 'package:rota_prime/screens/controle_gastos_screen.dart';
import 'package:rota_prime/screens/finalizar_rota_screen.dart';
import 'package:rota_prime/screens/home_map_screen.dart';
import 'package:rota_prime/widgets/map_layers_sheet.dart';
import 'package:rota_prime/widgets/planning_route_map_layer.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/widgets/circuit_stop_ui.dart';
import 'package:rota_prime/widgets/stop_detail_body.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rota_prime/services/speech_search_input.dart';
import 'package:rota_prime/app/app_navigator.dart';
import 'package:rota_prime/widgets/add_parada_sheet.dart';
import 'package:rota_prime/widgets/manual_parada_dialog.dart';
import 'package:rota_prime/widgets/route_finalize_flow.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/widgets/pro_gate.dart';
import 'package:rota_prime/widgets/route_options_sheet.dart';
import 'package:rota_prime/widgets/same_address_map_alert.dart';
import 'package:rota_prime/widgets/spoke_widgets.dart';
import 'package:rota_prime/widgets/stop_action_panel.dart';
import 'package:rota_prime/services/clustering_service.dart';
import 'package:rota_prime/services/map_pin_icon_cache.dart';
import 'package:rota_prime/services/map_tile_prefetch.dart';
import 'package:rota_prime/utils/parada_map_markers.dart';
import 'package:rota_prime/utils/route_map_stamp.dart';
import 'package:rota_prime/services/spreadsheet_picker.dart';
import 'package:rota_prime/utils/map_screen_layout.dart';
import 'package:rota_prime/widgets/route_map_mode_toggle.dart';
import 'package:rota_prime/app/map_performance.dart';
import 'package:rota_prime/utils/rota_map_controller.dart';
import 'package:rota_prime/utils/route_delivery_stats.dart';
import 'package:rota_prime/widgets/map_chrome.dart';
import 'package:rota_prime/widgets/delivery_map_legend.dart';
import 'package:rota_prime/widgets/saved_routes_menu_sheet.dart';
import 'package:rota_prime/widgets/route_map_header_bar.dart';
import 'package:rota_prime/widgets/route_planning_action_bar.dart';

class RotaMapaScreen extends ConsumerStatefulWidget {
  const RotaMapaScreen({
    super.key,
    this.openSearchOnStart = false,
    this.embeddedInShell = false,
  });

  final bool openSearchOnStart;
  final bool embeddedInShell;

  @override
  ConsumerState<RotaMapaScreen> createState() => _RotaMapaScreenState();
}

class _RotaMapaScreenState extends ConsumerState<RotaMapaScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.embeddedInShell;

  final _mapController = RotaMapController();
  final _sheetController = DraggableScrollableController();
  final _searchController = TextEditingController();
  bool _optimized = false;
  int? _selectedParadaId;
  final _searchQueryListenable = ValueNotifier('');

  static const _sheetMinSize = 0.02;
  static const _sheetListSize = 0.58;
  static const _sheetSnapSizes = [0.02, 0.58, 0.88];

  RouteMapPanelMode _panelMode = RouteMapPanelMode.map;
  bool _deliveryDockExpanded = false;
  /// false = painel da parada (pin); true = roteiro scrollável (botão X estilo Spok).
  bool _showItineraryInSheet = true;
  bool _sheetListenerAttached = false;

  /// Equivalente a `Map<String, BitmapDescriptor>` (Google Maps) — estilos ~32 px.
  late final Map<String, TextStyle> _iconCache;
  List<ClusterMapPoint> _clusterSource = [];
  List<MapPinCluster>? _viewportClusters;
  int _viewportRefreshGen = 0;
  Object? _lastClusterParadasStamp;
  bool _isRefreshingViewport = false;
  bool _optimizeInProgress = false;

  bool _viewportCullEnabled(List<Parada> paradas) =>
      paradas.length > MapPerformance.heavyStopCount;

  @override
  void initState() {
    super.initState();
    final pinIcons = MapPinIconCache()..preload();
    _iconCache = pinIcons.cache;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapPlanningMap());
    });
  }

  void _rebuildClusterSource(List<Parada> paradas) {
    final reps = representativeParadasForMap(paradas, hideCompleted: false);
    final pts = buildMapMarkerDisplayPoints(paradas);
    final labels = ParadaLabels.mapPinDisplayLabelsForRepresentatives(paradas, reps);
    _clusterSource = [
      for (final p in reps)
        if (p.latitude != null && p.longitude != null)
          ClusterMapPoint(
            paradaId: p.id,
            latitude: pts[p.id]?.latitude ?? p.latitude!,
            longitude: pts[p.id]?.longitude ?? p.longitude!,
            pinLabel: labels[p.id] ?? ParadaLabels.mapPinDisplayLabel(paradas, p),
          ),
    ];
    if (_viewportCullEnabled(paradas)) {
      _viewportClusters = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshViewportMarkers();
      });
    } else {
      _viewportClusters = null;
    }
  }

  void _syncClusterSourceIfNeeded(List<Parada> paradas) {
    final stamp = routeMapParadasStamp(paradas);
    if (stamp == _lastClusterParadasStamp) return;
    _lastClusterParadasStamp = stamp;
    _rebuildClusterSource(paradas);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _refreshViewportMarkers() {
    unawaited(_refreshViewportMarkersAsync());
  }

  Future<void> _refreshViewportMarkersAsync() async {
    if (_isRefreshingViewport) return;
    final paradas = ref.read(rotaProvider).paradas;
    if (!mounted || !_viewportCullEnabled(paradas)) {
      if (_viewportClusters != null && mounted) {
        setState(() => _viewportClusters = null);
      }
      return;
    }
    if (_clusterSource.isEmpty) return;

    _isRefreshingViewport = true;
    _viewportRefreshGen++;
    final gen = _viewportRefreshGen;
    try {
      final bounds = await _mapController.visibleBoundsAsync();
      if (bounds == null) return;
      final visible = filtrarPorBounds(
        _clusterSource,
        south: bounds.south,
        north: bounds.north,
        west: bounds.west,
        east: bounds.east,
      ).toList();
      final clusters = clusterizar(visible);
      if (!mounted || gen != _viewportRefreshGen) return;
      setState(() => _viewportClusters = clusters);
    } finally {
      _isRefreshingViewport = false;
    }
  }

  Future<void> _bootstrapPlanningMap() async {
    _attachSheetListener();
    await ref.read(rotaProvider.notifier).refreshDriverLocation();
    final rota = ref.read(rotaProvider).rota;
    final isPro = ref.read(subscriptionProvider).isPro;
    final paradas = ref.read(rotaProvider).paradas;
    final nStops = paradas.length;
    if (nStops >= MapPerformance.listFirstStopCount) {
      if (mounted) {
        setState(() => _panelMode = RouteMapPanelMode.list);
        _applyPanelMode(RouteMapPanelMode.list, animate: false);
      }
    } else {
      _enterDriverMapMode(animate: false);
    }
    if (rota?.otimizada == true) {
      if (mounted) setState(() => _optimized = true);
      if (paradas.length <= 45) {
        unawaited(_syncNavigationTraceForTarget());
      }
    } else if (paradas.isNotEmpty) {
      unawaited(_applyImportOrderInBackground(isPro));
    }
    if (widget.openSearchOnStart && mounted) {
      _showSearchAndAddDialog();
    }
    if (!mounted) return;
    final toFit = ref.read(rotaProvider).paradas;
    if (toFit.isEmpty) return;
    final n = toFit.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fitRotaMapControllerToParadas(
        _mapController,
        toFit,
        maxZoom: n > 70 ? 13 : 16,
        focusNear: ref.read(rotaProvider).driverPosition,
        ultraFast: n >= MapPerformance.listFirstStopCount,
      );
      _rebuildClusterSource(toFit);
      _refreshViewportMarkers();
    });
  }

  Future<void> _applyImportOrderInBackground(bool isPro) async {
    await ref.read(rotaProvider.notifier).applySpreadsheetOrderOnly();
    if (!mounted || isPro) return;
    setState(() => _optimized = true);
  }

  void _attachSheetListener() {
    if (_sheetListenerAttached) return;
    _sheetListenerAttached = true;
    _sheetController.addListener(_onSheetDragSyncMode);
  }

  void _onSheetDragSyncMode() {
    if (!_sheetController.isAttached || !mounted) return;
    final s = _sheetController.size;
    final inferred =
        s <= _sheetMinSize + 0.06 ? RouteMapPanelMode.map : RouteMapPanelMode.list;
    if (inferred != _panelMode) {
      setState(() => _panelMode = inferred);
    }
  }

  void _applyPanelMode(RouteMapPanelMode mode, {bool animate = true}) {
    _panelMode = mode;
    void applyWhenReady() {
      if (!_sheetController.isAttached) {
        WidgetsBinding.instance.addPostFrameCallback((_) => applyWhenReady());
        return;
      }
      final target = mode == RouteMapPanelMode.list ? _sheetListSize : _sheetMinSize;
      if (animate) {
        _sheetController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _sheetController.jumpTo(target);
      }
    }

    applyWhenReady();
  }

  void _enterDriverMapMode({bool animate = true, bool expandDelivery = false}) {
    setState(() {
      _panelMode = RouteMapPanelMode.map;
      _deliveryDockExpanded = expandDelivery;
    });
    _applyPanelMode(RouteMapPanelMode.map, animate: animate);
  }

  void _onPanelModeChanged(RouteMapPanelMode mode) {
    setState(() {
      _panelMode = mode;
      _deliveryDockExpanded = mode == RouteMapPanelMode.list;
    });
    _applyPanelMode(mode);
  }

  void _selectNextPendingParada() {
    final paradas = ref.read(rotaProvider).paradas;
    final isPro = ref.read(subscriptionProvider).isPro;
    final optimized = ref.read(rotaProvider).rota?.otimizada == true;
    for (final p in paradas) {
      if (!p.entregue && !p.falha) {
        if (isPro && optimized) {
          unawaited(
            ref.read(rotaProvider.notifier).selectNavigationTarget(p.id),
          );
        }
        setState(() => _selectedParadaId = p.id);
        _moveToParada(p);
        return;
      }
    }
    setState(() => _selectedParadaId = null);
  }

  Future<void> _syncNavigationTraceForTarget({int? paradaId}) async {
    final isPro = ref.read(subscriptionProvider).isPro;
    if (!isPro || ref.read(rotaProvider).rota?.otimizada != true) return;
    final nav = ref.read(rotaProvider.notifier);
    if (paradaId != null) {
      await nav.selectNavigationTarget(paradaId, awaitLegRefresh: true);
      if (mounted) setState(() => _selectedParadaId = paradaId);
      return;
    }
    await nav.syncActiveNavigationTarget();
    await nav.refreshNavigationLegForActiveTarget(force: true);
    final active = RotaNotifier.activeNavigationParadaFrom(
      ref.read(rotaProvider),
      isPro: true,
    );
    if (active != null && mounted) {
      setState(() => _selectedParadaId = active.id);
    }
  }

  @override
  void dispose() {
    if (_sheetListenerAttached) {
      _sheetController.removeListener(_onSheetDragSyncMode);
    }
    _sheetController.dispose();
    _searchController.dispose();
    _searchQueryListenable.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Parada? _selectedParada(List<Parada> paradas) {
    if (_selectedParadaId == null) return null;
    for (final p in paradas) {
      if (p.id == _selectedParadaId) return p;
    }
    return null;
  }

  void _expandStopSheet() {
    if (!_sheetController.isAttached) return;
    setState(() => _panelMode = RouteMapPanelMode.list);
    _sheetController.animateTo(
      0.72,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _expandSheetForStopDetail() {
    if (!_sheetController.isAttached) return;
    _sheetController.animateTo(
      0.56,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _closeStopDetailOpenItinerary() {
    setState(() {
      _showItineraryInSheet = true;
      _selectedParadaId = null;
      _panelMode = RouteMapPanelMode.list;
    });
    if (!_sheetController.isAttached) return;
    _sheetController.animateTo(
      0.88,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _moveToParada(Parada p) {
    if (p.latitude == null || p.longitude == null) return;
    final h = MediaQuery.of(context).size.height;
    _mapController.move(
      LatLng(p.latitude!, p.longitude!),
      15,
      offset: Offset(0, h * 0.06),
    );
  }

  Future<void> _openParada(Parada p, {bool fromMapPin = false}) async {
    if (fromMapPin) {
      await showSameAddressDeliveriesAlertIfNeeded(
        context,
        all: ref.read(rotaProvider).paradas,
        tapped: p,
      );
      if (!mounted) return;
    }
    final isPro = ref.read(subscriptionProvider).isPro;
    final optimized = ref.read(rotaProvider).rota?.otimizada == true;
    if (isPro && optimized) {
      ref.read(rotaProvider.notifier).selectNavigationTarget(p.id);
    }
    setState(() {
      _selectedParadaId = p.id;
      _deliveryDockExpanded = true;
      _showItineraryInSheet = false;
    });
    if (fromMapPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _expandSheetForStopDetail());
    } else if (_panelMode == RouteMapPanelMode.list) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _expandStopSheet());
    }
  }

  Future<void> _duplicateParada(Parada p) async {
    final dup = await ref.read(rotaProvider.notifier).duplicateParada(p.id);
    if (!mounted || dup == null) return;
    setState(() {
      _selectedParadaId = dup.id;
      _optimized = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parada duplicada — otimize de novo se precisar')),
    );
  }

  Future<void> _confirmRemoveParada(Parada p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        title: const Text('Remover parada?', style: TextStyle(color: Colors.white)),
        content: Text(
          p.destinationAddress.trim().isNotEmpty
              ? p.destinationAddress.trim()
              : 'Esta entrega será excluída da rota.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final removed = await ref.read(rotaProvider.notifier).removeParada(p.id);
    if (!mounted || !removed) return;
    setState(() {
      _selectedParadaId = null;
      _optimized = ref.read(rotaProvider).rota?.otimizada == true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parada removida')),
    );
  }

  Future<void> _editParada(Parada p) async {
    final updated = await showEditParadaDialog(context, ref, p);
    if (!mounted || updated == null) return;
    setState(() => _selectedParadaId = updated.id);
    _moveToParada(updated);
    final isPro = ref.read(subscriptionProvider).isPro;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Endereço atualizado no mapa'),
        action: isPro
            ? SnackBarAction(
                label: 'Otimizar',
                onPressed: _otimizar,
              )
            : null,
      ),
    );
  }

  Future<void> _openExternalNav(Parada p) async {
    if (p.latitude == null || p.longitude == null) return;
    final waze = Uri.parse('waze://?q=${p.latitude},${p.longitude}&navigate=yes');
    if (await canLaunchUrl(waze)) {
      await launchUrl(waze);
      return;
    }
    final gmaps = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}',
    );
    await launchUrl(gmaps, mode: LaunchMode.externalApplication);
  }

  Future<void> _markDelivered(Parada p) async {
    final next = await ref.read(rotaProvider.notifier).markEntregue(
          p.id,
          entregue: true,
          falha: false,
        );
    if (!mounted) return;
    if (next != null) {
      _openParada(next);
    } else {
      setState(() {
        _selectedParadaId = null;
        if (_panelMode == RouteMapPanelMode.map) {
          _deliveryDockExpanded = false;
        }
      });
    }
  }

  Future<void> _searchRouteByVoice() async {
    final q = await listenRouteSearchQuery(context);
    if (!mounted || q == null) return;
    _searchController.text = q;
    _searchQueryListenable.value = q;
  }

  Future<void> _onRouteSearchMic() async {
    if (_searchController.text.trim().isEmpty) {
      final added = await showAddParadaOptionsSheet(
        rootAppContext ?? context,
        ref,
      );
      if (!mounted || added == null) return;
      await _openParada(added);
      return;
    }
    await _searchRouteByVoice();
  }

  Future<void> _openRouteScanMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.orange),
              title: const Text('Escanear pacote', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'QR ou código de barras do pacote',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              onTap: () => Navigator.pop(ctx, 'pack'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined, color: AppColors.orange),
              title: const Text('Importar romaneio', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'PDF ou planilha de rotas',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              onTap: () => Navigator.pop(ctx, 'import'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'pack') {
      await _scanPackageQr();
    } else if (choice == 'import') {
      if (ref.read(rotaProvider).paradas.isEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FilePickerScreen()),
        );
      } else {
        await pickSpreadsheetAndMergeIntoRoute(ref);
      }
    }
  }

  Future<void> _scanPackageQr() async {
    final result = await openQrParadaFlow(context, ref);
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.spxTn.isNotEmpty
              ? 'Pacote ${result.spxTn} · parada ${result.ordemExibicao}'
              : 'Parada ${result.ordemExibicao} selecionada',
        ),
      ),
    );
    await _openParada(result);
  }

  Future<void> _finishRouteFromItinerary() async {
    await runSpokStyleRouteFinishFlow(
      context,
      ref,
      onCopyStops: _copyStops,
    );
  }

  Future<void> _addParadaManual() async {
    final added = await openManualParadaFlow(context, ref);
    if (!mounted || added == null) return;
    final routeActive =
        ref.read(rotaProvider).rota?.status == RotaStatus.ativa;
    setState(() {
      _selectedParadaId = added.id;
      if (!routeActive) {
        _deliveryDockExpanded = false;
      }
    });
    if (routeActive) {
      _openParada(added);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.card,
          content: Text(
            routeActive
                ? 'Parada adicionada à rota'
                : 'Parada adicionada · use + para incluir outra ou otimize quando terminar',
          ),
        ),
      );
  }

  void _showSearchAndAddDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        title: const Text('Pesquisar ou adicionar', style: TextStyle(color: Colors.white)),
        content: TextField(
          autofocus: true,
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Endereço, código ou bairro',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          onChanged: (v) => _searchQueryListenable.value = v,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _searchQueryListenable.value = '';
              Navigator.pop(ctx);
            },
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _addParadaManual();
              if (mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Adicionar entrega'),
          ),
        ],
      ),
    );
  }

  Future<void> _useImportOrder() async {
    await ref.read(rotaProvider.notifier).applySpreadsheetOrderOnly();
    if (!mounted) return;
    setState(() => _optimized = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ordem do romaneio (1, 2, 3…) — sequência crescente, sem rota laranja',
        ),
      ),
    );
  }

  Future<void> _otimizar() async {
    if (!mounted || _optimizeInProgress) return;
    if (!await ensureProOrPrompt(context, ref, feature: 'Otimização de rota')) return;
    if (!mounted) return;
    setState(() => _optimizeInProgress = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final statusMessage =
              ref.watch(rotaProvider.select((s) => s.statusMessage));
          final progress =
              ref.watch(rotaProvider.select((s) => s.optimizeProgress));
          return OptimizingRouteDialog(
            statusMessage: statusMessage,
            progress: progress,
          );
        },
      ),
    );

    try {
      await ref.read(rotaProvider.notifier).optimizeRoute(
            isPro: ref.read(subscriptionProvider).isPro,
          );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _optimized = true);
      final nStops = ref.read(rotaProvider).paradas.length;
      if (nStops > PlanningRouteMapLayer.maxStopsFullPolyline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Rota otimizada. Com muitas paradas a linha no mapa fica desligada '
              'para não travar — use a lista e os números nos pins.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      _enterDriverMapMode(animate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_syncNavigationTraceForTarget());
      });
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await showOsrmFailDialog(
        context,
        onRetry: _otimizar,
        onSkip: () => setState(() => _optimized = true),
      );
      return;
    } finally {
      if (mounted) setState(() => _optimizeInProgress = false);
    }
  }

  Future<void> _deleteRoute() async {
    final notifier = ref.read(rotaProvider.notifier);
    final ok = await showDialog<bool>(
      barrierDismissible: true,
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        title: const Text('Excluir rota?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Todas as paradas desta rota serão removidas.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            color: AppColors.sheet,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.orange),
                  SizedBox(height: 16),
                  Text('Removendo rota…', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    try {
      await notifier.deleteCurrentRoute();
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeMapScreen()),
      (r) => false,
    );
  }

  Future<void> _copyStops() async {
    final state = ref.read(rotaProvider);
    final lines = state.paradas
        .map((p) => '${p.ordemExibicao}. ${p.spxTn} — ${p.destinationAddress}')
        .toList();
    await copyRouteSummaryToClipboard(
      title: state.rota?.titulo ?? 'Rota',
      stopCount: state.totalParadas,
      lines: lines,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paradas copiadas para a área de transferência')),
    );
  }

  void _openRouteOptions() {
    showRouteOptionsSheet(
      context,
      onReoptimize: () async {
        if (!await ensureProOrPrompt(context, ref, feature: 'Reotimizar rota')) return;
        await _otimizar();
      },
      onDeleteRoute: _deleteRoute,
      onFinishRoute: () async {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FinalizarRotaScreen()),
        );
      },
      onHistory: () async {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ContaRotasScreen()),
        );
      },
      routeHasRomaneioStops: ref.read(rotaProvider).paradas.isNotEmpty,
      onImportRomaneio: () async {
        if (!mounted) return;
        if (ref.read(rotaProvider).paradas.isEmpty) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FilePickerScreen()),
          );
        } else {
          await pickSpreadsheetAndMergeIntoRoute(ref);
        }
      },
      onCopyStops: _copyStops,
      onRefreshGps: () => ref.read(rotaProvider.notifier).refreshDriverLocation(),
      onControleGastos: () => openControleGastosPro(context, ref),
      onAddParadaManual:
          ref.read(rotaProvider).allowManualParadaEntry ? _addParadaManual : null,
    );
  }

  void _openAppMenu() {
    if (widget.embeddedInShell) {
      switchAppShellTab(ref, 3);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContaRotasScreen()),
    );
  }

  String _etaForStop(int ordem, int totalMin, int totalStops) {
    if (totalStops <= 0) return '--:--';
    final avgStop = ref.read(mapSettingsProvider).avgStopMinutes;
    final start = DateTime.now();
    final travel = (totalMin * (ordem - 1) / totalStops).round();
    final minutes = travel + avgStop * (ordem - 1);
    return DateFormat('HH:mm').format(start.add(Duration(minutes: minutes)));
  }

  String _terminoLabel(int totalMin) {
    return DateFormat('HH:mm').format(DateTime.now().add(Duration(minutes: totalMin)));
  }

  List<Parada> _filteredParadas(List<Parada> paradas, String searchQuery) {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return paradas;
    return paradas.where((p) {
      return p.destinationAddress.toLowerCase().contains(q) ||
          p.spxTn.toLowerCase().contains(q) ||
          p.rawLine.toLowerCase().contains(q) ||
          p.bairro.toLowerCase().contains(q);
    }).toList();
  }

  void _centerOnDriver() {
    final pos = ref.read(rotaProvider).driverPosition;
    if (pos == null) {
      ref.read(rotaProvider.notifier).refreshDriverLocation();
      return;
    }
    _mapController.move(pos, 18);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<bool>(mapTabOpenSearchProvider, (prev, openSearch) {
      if (openSearch && widget.embeddedInShell && mounted) {
        ref.read(mapTabOpenSearchProvider.notifier).state = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showSearchAndAddDialog();
        });
      }
    });

    final paradas = ref.watch(rotaProvider.select((s) => s.paradas));
    final rota = ref.watch(rotaProvider.select((s) => s.rota));
    final totalParadas = ref.watch(rotaProvider.select((s) => s.totalParadas));
    final totalPacotes = ref.watch(rotaProvider.select((s) => s.totalPacotes));
    final allowManualAdd =
        ref.watch(rotaProvider.select((s) => s.allowManualParadaEntry));
    final useGpsOrigin = ref.watch(rotaProvider.select((s) => s.useGpsOrigin));
    final routeOptimized = rota?.otimizada == true;
    final dur = routeOptimized ? (rota?.duracaoMinutos ?? 0) : 0;
    final h = dur ~/ 60;
    final m = dur % 60;
    final dist = routeOptimized
        ? (rota?.distanciaKm ?? 0).toStringAsFixed(1).replaceAll('.', ',')
        : '';
    final isPro = ref.watch(subscriptionProvider).isPro;
    final routeTotalsLabel = totalPacotes == totalParadas
        ? '$totalParadas paradas'
        : '$totalParadas paradas · $totalPacotes pacotes';
    final routeActive = rota?.status == RotaStatus.ativa;
    final selectedParada = _selectedParada(paradas);
    final previousInRoute = selectedParada != null
        ? RotaNotifier.previousInRouteOrder(paradas, selectedParada)
        : null;
    final nextInRoute = selectedParada != null
        ? RotaNotifier.nextPendingInRouteOrderAfter(paradas, selectedParada)
        : null;
    final multiStopsOnMap = paradas.length > 1;
    final compactDeliveryDock =
        _panelMode == RouteMapPanelMode.map && !_deliveryDockExpanded;
    final bottomInset = mapScreenBottomInset(context, embeddedInShell: widget.embeddedInShell);
    final importedPkg = rota?.pacotesImportados;
    final deliveriesDone = RouteDeliveryStats.finishedPackages(paradas);
    final deliveriesTotal = RouteDeliveryStats.packageDenominator(
      paradas,
      importedTotal: importedPkg != null && importedPkg > 0 ? importedPkg : null,
    );
    final distanceHeader = routeOptimized && dist.isNotEmpty ? '$dist km' : '—';
    final durationHeader = routeOptimized && dur > 0
        ? (m > 0 ? '${h}h ${m}min' : '${h}h')
        : (paradas.isEmpty ? '—' : 'Planilha');
    final listBottomPad = 20.0;
    final dockH = paradas.isNotEmpty
        ? mapFooterReserve(
            hasParadas: true,
            compactDeliveryDock: compactDeliveryDock,
            paradaSelected: selectedParada != null,
            optimizedRow: _optimized && selectedParada == null,
          )
        : 0.0;
    final sheetChromeBottom = dockH + bottomInset;
    final sheetAreaHeight = MediaQuery.sizeOf(context).height - sheetChromeBottom;

    _syncClusterSourceIfNeeded(paradas);

    final content = SafeArea(
        bottom: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: PlanningRouteMapLayer(
                rotaMapController: _mapController,
                selectedParadaId: _selectedParadaId,
                onParadaTap: (p) => _openParada(p, fromMapPin: true),
                viewportClusters: _viewportCullEnabled(paradas)
                    ? _viewportClusters
                    : null,
                pinIconStyles: _iconCache,
                onCameraMove: _viewportCullEnabled(paradas)
                    ? _refreshViewportMarkers
                    : null,
                onCameraIdle: _viewportCullEnabled(paradas)
                    ? _refreshViewportMarkers
                    : null,
              ),
            ),
            const Positioned.fill(child: MapTopScrim(height: 120)),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: sheetChromeBottom,
              child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _sheetMinSize,
              minChildSize: _sheetMinSize,
              maxChildSize: 0.88,
              snap: true,
              snapSizes: _sheetSnapSizes,
              builder: (context, scrollController) {
                return Consumer(
                  builder: (context, ref, _) {
                    final sheetParadas = ref.watch(
                      rotaProvider.select((s) => s.paradas),
                    );
                    final selectedColumns = ref.watch(
                      rotaProvider.select((s) => s.selectedColumns),
                    );
                    final selected = _selectedParada(sheetParadas);
                    final mapSettings = ref.watch(mapSettingsProvider);

                    return Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        color: AppColors.sheet,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: selected != null && !_showItineraryInSheet
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (allowManualAdd)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                          child: OutlinedButton.icon(
                                            onPressed: _addParadaManual,
                                            icon: const Icon(Icons.add_location_alt_outlined),
                                            label: const Text('Adicionar entrega manualmente'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.orange,
                                              side: const BorderSide(color: AppColors.orange),
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          controller: scrollController,
                                          padding: EdgeInsets.fromLTRB(16, 0, 16, listBottomPad),
                                          child: StopDetailBody(
                                            parada: selected,
                                            totalStops: totalPacotes,
                                            allParadas: paradas,
                                            selectedColumns: selectedColumns,
                                            stopIdDisplay: mapSettings.stopIdDisplay,
                                            emphasizedStopHeader: true,
                                            compactSheet: true,
                                            omitAddressAndPackageTiles: true,
                                            onClose: _closeStopDetailOpenItinerary,
                                            onEdit: () => _editParada(selected),
                                            onDuplicate: () => _duplicateParada(selected),
                                            onRemove: () => _confirmRemoveParada(selected),
                                            onNavigate: () => _openExternalNav(selected),
                                            onPrevious: previousInRoute == null
                                                ? null
                                                : () => _openParada(previousInRoute),
                                            onNext: nextInRoute == null
                                                ? null
                                                : () => _openParada(nextInRoute),
                                            onFailed: () =>
                                                ref.read(rotaProvider.notifier).markEntregue(
                                                      selected.id,
                                                      entregue: false,
                                                      falha: true,
                                                    ),
                                            onDelivered: () => _markDelivered(selected),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ValueListenableBuilder<String>(
                                    valueListenable: _searchQueryListenable,
                                    builder: (context, searchQuery, _) {
                                      final visibleParadas =
                                          _filteredParadas(sheetParadas, searchQuery);
                                      final driverPosition =
                                          ref.read(rotaProvider).driverPosition;
                                      return CustomScrollView(
                                    controller: scrollController,
                                    physics: const ClampingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                    slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, listBottomPad),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                          const SizedBox(height: 4),
                          RouteSearchBar(
                            controller: _searchController,
                            onChanged: (v) => _searchQueryListenable.value = v,
                            onScan: _openRouteScanMenu,
                            onMic: _onRouteSearchMic,
                            onMore: () => showSavedRoutesMenuSheet(
                              context,
                              ref,
                              embeddedInShell: widget.embeddedInShell,
                              onRouteOptions: _openRouteOptions,
                            ),
                          ),
                          if (allowManualAdd) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _addParadaManual,
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: const Text('Adicionar entrega manualmente'),
                            ),
                          ],
                          if (paradas.isEmpty) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => pickSpreadsheetAndImport(ref),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Importar 1º romaneio'),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => pickSpreadsheetAndMergeIntoRoute(ref),
                              icon: const Icon(Icons.library_add_outlined),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.orange,
                                side: const BorderSide(color: AppColors.orange),
                              ),
                              label: const Text('Adicionar outro romaneio'),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _optimized
                                      ? (routeOptimized
                                          ? 'Término: ${_terminoLabel(dur)} • $routeTotalsLabel • $dist km'
                                          : 'Ordem da planilha • $routeTotalsLabel')
                                      : routeTotalsLabel,
                                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppColors.sheet,
                                      title: const Text(
                                        'Buscar parada',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: TextField(
                                        autofocus: true,
                                        controller: _searchController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: const InputDecoration(
                                          hintText: 'Código ou endereço',
                                          hintStyle: TextStyle(color: Colors.white38),
                                        ),
                                        onChanged: (v) => _searchQueryListenable.value = v,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            _searchQueryListenable.value = '';
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Limpar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Fechar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.search, color: Colors.white54, size: 22),
                              ),
                              IconButton(
                                onPressed: _openRouteOptions,
                                icon: const Icon(Icons.more_vert, color: Colors.white54, size: 22),
                              ),
                            ],
                          ),
                          Text(
                            rota?.titulo ?? 'Rota',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: useGpsOrigin,
                            activeTrackColor: AppColors.orange,
                            title: const Text(
                              'Iniciar no local atual (GPS)',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Use a posição exata ao otimizar',
                              style: TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                            onChanged: (v) => ref.read(rotaProvider.notifier).setUseGpsOrigin(v),
                          ),
                          if (!_optimized) ...[
                            const RouteConfigTile(
                              title: 'Ida e volta',
                              subtitle: 'Retorne ao ponto de partida',
                              trailingIcon: Icons.sync_alt,
                            ),
                            const RouteConfigTile(
                              title: 'Sem pausa',
                              subtitle: 'Toque para agendar uma pausa',
                              trailingIcon: Icons.local_cafe_outlined,
                            ),
                            const SizedBox(height: 8),
                          ] else ...[
                            const RouteTimelineStop(
                              indexLabel: '',
                              timeLabel: '',
                              title: 'Sem pausa / Toque para agendar uma pausa',
                              subtitle: '',
                              isPause: true,
                            ),
                            RouteTimelineStop(
                              indexLabel: '',
                              timeLabel: DateFormat('HH:mm').format(DateTime.now()),
                              title: 'Ponto de partida',
                              subtitle: driverPosition != null
                                  ? 'GPS atual'
                                  : 'Origem da rota',
                              isStart: true,
                            ),
                          ],
                                ],
                              ),
                            ),
                          ),
                          if (!_optimized && visibleParadas.isNotEmpty)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, listBottomPad),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => RepaintBoundary(
                                    child: _paradaTile(visibleParadas[i]),
                                  ),
                                  childCount: visibleParadas.length,
                                ),
                              ),
                            )
                          else if (_optimized && visibleParadas.isNotEmpty)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, listBottomPad),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final p = visibleParadas[i];
                                    final last = i == visibleParadas.length - 1;
                                    return RepaintBoundary(
                                      child: InkWell(
                                        onTap: () => _openParada(p),
                                        child: RouteTimelineStop(
                                          indexLabel: ParadaLabels.mapPinLabel(paradas, p),
                                          showPackageOrderIcon: true,
                                          packageOrderOnIcon:
                                              ParadaLabels.packageOrderDisplay(p, route: paradas),
                                          timeLabel: _etaForStop(
                                            p.ordemExibicao,
                                            dur,
                                            totalPacotes,
                                          ),
                                          title: p.destinationAddress,
                                          subtitle: [
                                            ParadaLabels.packageQtyLine(paradas, p),
                                            'Rota ${ParadaLabels.routeProgress(paradas, p, totalPackages: totalPacotes)}',
                                            if (p.stop > 0 && p.stop != ParadaLabels.packageOrder(p))
                                              'Parada ${p.stop}',
                                            if (p.bairro.isNotEmpty) p.bairro,
                                            if (p.city.isNotEmpty) p.city,
                                          ].where((s) => s.isNotEmpty).join(' · '),
                                          rawLine: p.rawLine.isNotEmpty ? p.rawLine : p.spxTn,
                                          badge: ParadaLabels.mapPinLabel(paradas, p),
                                          isLast: last,
                                          actions: PopupMenuButton<String>(
                                            tooltip: 'Mais opções',
                                            icon: const Icon(
                                              Icons.more_vert,
                                              color: Colors.white54,
                                              size: 20,
                                            ),
                                            color: AppColors.card,
                                            onSelected: (value) {
                                              if (value == 'edit') _editParada(p);
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_location_alt_outlined, size: 20),
                                                    SizedBox(width: 10),
                                                    Text('Editar endereço'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: visibleParadas.length,
                                ),
                              ),
                            ),
                          if (sheetParadas.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: OutlinedButton.icon(
                                  onPressed: _finishRouteFromItinerary,
                                  icon: const Icon(Icons.flag_outlined),
                                  label: Text(
                                    routeActive
                                        ? 'Marcar rota como finalizada'
                                        : 'Finalizar rota',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: AppColors.orange.withValues(alpha: 0.75),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                                    ],
                                  );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            ),
            if (paradas.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RouteMapModeToggle(
                      mode: _panelMode,
                      onModeChanged: _onPanelModeChanged,
                    ),
                    if (compactDeliveryDock)
                      DeliveryActionsPeekBar(
                        subtitle: selectedParada != null
                            ? 'Parada selecionada · toque para entregar ou GPS'
                            : null,
                        onTap: () => setState(() => _deliveryDockExpanded = true),
                      )
                    else ...[
                      if (_panelMode == RouteMapPanelMode.map)
                        DeliveryDockCollapseStrip(
                          onCollapse: () => setState(() => _deliveryDockExpanded = false),
                        ),
                      MapBottomDock(
                        flatTop: true,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: selectedParada != null && routeActive
                            ? StopActionPanel(
                                routePeek: StopRouteAddressPeek.fromParadas(
                                  paradas,
                                  selectedParada,
                                  next: multiStopsOnMap ? nextInRoute : null,
                                ),
                                onPrevious: !multiStopsOnMap || previousInRoute == null
                                    ? null
                                    : () => _openParada(previousInRoute),
                                onNext: !multiStopsOnMap || nextInRoute == null
                                    ? null
                                    : () => _openParada(nextInRoute),
                                onFailed: () => ref.read(rotaProvider.notifier).markEntregue(
                                      selectedParada.id,
                                      entregue: false,
                                      falha: true,
                                    ),
                                onDelivered: () => _markDelivered(selectedParada),
                              )
                            : RoutePlanningActionBar(
                                optimized: _optimized,
                                isPro: isPro,
                                optimizing: _optimizeInProgress,
                                onOptimize: _otimizar,
                                onUseImportOrder: _useImportOrder,
                                onStart: () async {
                                  final st = ref.read(rotaProvider);
                                  await ref.read(rotaProvider.notifier).confirmRoute();
                                  final basemap =
                                      ref.read(mapSettingsProvider).basemap;
                                  MapTilePrefetch.prefetchUserBasemapForRoute(
                                    paradas: st.paradas,
                                    basemap: basemap,
                                    onProgress: (msg) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(msg),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  );
                                  if (!context.mounted) return;
                                  _selectNextPendingParada();
                                  _enterDriverMapMode(expandDelivery: false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Rota iniciada — acompanhe entregas e tempo no topo',
                                      ),
                                    ),
                                  );
                                },
                                onRefine: _otimizar,
                                durationLabel: routeOptimized
                                    ? '${h}h ${m.toString().padLeft(2, '0')}min'
                                    : 'Planilha',
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RouteMapHeaderBar(
                    deliveriesDone: deliveriesDone,
                    deliveriesTotal: deliveriesTotal,
                    distanceLabel: distanceHeader,
                    durationLabel: durationHeader,
                    routeTitle: rota?.titulo,
                    onMenu: _openAppMenu,
                  ),
                  if (allowManualAdd)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _addParadaManual,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(Icons.add_location_alt_outlined, color: AppColors.orange, size: 22),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Adicionar entrega manualmente',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.4)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: _sheetController,
              builder: (context, _) {
                final size = (_sheetController.isAttached
                        ? (_sheetController.size * 15).round() / 15.0
                        : 0.4)
                    .clamp(_sheetMinSize, 0.88);
                final controlsBottom = mapFloatingControlsBottom(
                  sheetChromeBottom: sheetChromeBottom,
                  sheetAreaHeight: sheetAreaHeight,
                  sheetSize: size,
                  gap: 18,
                );
                return Positioned(
                  right: 10,
                  bottom: controlsBottom,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DeliveryMapLegend(),
                      const SizedBox(height: 10),
                      MapCircleButton(
                        icon: Icons.layers_outlined,
                        onTap: () => showMapLayersSheet(context, ref),
                      ),
                      const SizedBox(height: 8),
                      MapCircleButton(icon: Icons.my_location, onTap: _centerOnDriver),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );

    if (widget.embeddedInShell) {
      return ColoredBox(color: AppColors.background, child: content);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: content,
    );
  }

  Widget _paradaTile(Parada p) {
    final paradas = ref.read(rotaProvider).paradas;
    Color badge = AppColors.stopPending;
    IconData? icon;
    if (p.entregue) {
      badge = AppColors.successGreen;
      icon = Icons.check;
    } else if (p.falha) {
      badge = AppColors.stopFailed;
      icon = Icons.close;
    } else if (p.id == _selectedParadaId) {
      badge = AppColors.orange;
    }

    return Material(
      color: p.id == _selectedParadaId
          ? AppColors.card
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _openParada(p),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: badge, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 16)
                    : Text(
                        ParadaLabels.mapPinLabel(paradas, p),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.destinationAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      ParadaLabels.packageQtyLine(paradas, p),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    if (p.spxTn.isNotEmpty)
                      Text(
                        p.spxTn,
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              PackageOrderBadge(parada: p, allParadas: paradas, compact: true),
              PopupMenuButton<String>(
                tooltip: 'Mais opções',
                icon: const Icon(Icons.more_vert, color: Colors.white54, size: 22),
                color: AppColors.card,
                onSelected: (value) {
                  if (value == 'edit') _editParada(p);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_location_alt_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('Editar endereço'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
