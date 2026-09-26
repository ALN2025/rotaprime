import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
import 'package:rota_prime/widgets/route_map.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/widgets/circuit_stop_ui.dart';
import 'package:rota_prime/widgets/stop_detail_body.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rota_prime/services/speech_search_input.dart';
import 'package:rota_prime/widgets/add_parada_sheet.dart';
import 'package:rota_prime/widgets/manual_parada_dialog.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/widgets/pro_gate.dart';
import 'package:rota_prime/widgets/route_options_sheet.dart';
import 'package:rota_prime/widgets/spoke_widgets.dart';
import 'package:rota_prime/widgets/stop_action_panel.dart';
import 'package:rota_prime/services/map_tile_prefetch.dart';
import 'package:rota_prime/services/spreadsheet_picker.dart';
import 'package:rota_prime/utils/map_screen_layout.dart';
import 'package:rota_prime/widgets/route_map_mode_toggle.dart';
import 'package:rota_prime/utils/map_route_fit.dart';
import 'package:rota_prime/utils/route_delivery_stats.dart';
import 'package:rota_prime/widgets/map_chrome.dart';
import 'package:rota_prime/widgets/delivery_map_legend.dart';
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

class _RotaMapaScreenState extends ConsumerState<RotaMapaScreen> {
  final _mapController = MapController();
  final _sheetController = DraggableScrollableController();
  final _searchController = TextEditingController();
  bool _optimized = false;
  int? _selectedParadaId;
  String _searchQuery = '';

  static const _sheetMinSize = 0.02;
  static const _sheetListSize = 0.58;
  static const _sheetSnapSizes = [0.02, 0.58, 0.88];

  RouteMapPanelMode _panelMode = RouteMapPanelMode.map;
  bool _deliveryDockExpanded = false;
  bool _sheetListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _attachSheetListener();
      _enterDriverMapMode(animate: false);
      final rota = ref.read(rotaProvider).rota;
      final isPro = ref.read(subscriptionProvider).isPro;
      if (rota?.otimizada == true) {
        if (mounted) setState(() => _optimized = true);
      } else if (!isPro && ref.read(rotaProvider).paradas.isNotEmpty) {
        await ref.read(rotaProvider.notifier).applySpreadsheetOrderOnly();
        if (mounted) setState(() => _optimized = true);
      }
      if (widget.openSearchOnStart) {
        _showSearchAndAddDialog();
      }
      if (!mounted) return;
      fitMapControllerToParadas(_mapController, ref.read(rotaProvider).paradas);
    });
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
    for (final p in paradas) {
      if (!p.entregue && !p.falha) {
        setState(() => _selectedParadaId = p.id);
        _moveToParada(p);
        return;
      }
    }
    setState(() => _selectedParadaId = null);
  }

  @override
  void dispose() {
    if (_sheetListenerAttached) {
      _sheetController.removeListener(_onSheetDragSyncMode);
    }
    _sheetController.dispose();
    _searchController.dispose();
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

  void _moveToParada(Parada p) {
    if (p.latitude == null || p.longitude == null) return;
    final h = MediaQuery.of(context).size.height;
    _mapController.move(
      LatLng(p.latitude!, p.longitude!),
      15,
      offset: Offset(0, h * 0.06),
    );
  }

  void _openParada(Parada p) {
    final isPro = ref.read(subscriptionProvider).isPro;
    final optimized = ref.read(rotaProvider).rota?.otimizada == true;
    if (isPro && optimized) {
      ref.read(rotaProvider.notifier).selectNavigationTarget(p.id);
    }
    setState(() {
      _selectedParadaId = p.id;
      _deliveryDockExpanded = true;
    });
    if (_panelMode == RouteMapPanelMode.list) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _expandStopSheet());
    }
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
    setState(() => _searchQuery = q);
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
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
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
      _enterDriverMapMode(animate: true);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await showOsrmFailDialog(
        context,
        onRetry: _otimizar,
        onSkip: () => setState(() => _optimized = true),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _deleteRoute() async {
    final notifier = ref.read(rotaProvider.notifier);
    final ok = await showDialog<bool>(
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
    if (ok == true) {
      await notifier.deleteCurrentRoute();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeMapScreen()),
        (r) => false,
      );
    }
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

  List<Parada> _filteredParadas(List<Parada> paradas) {
    final q = _searchQuery.trim().toLowerCase();
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
    ref.listen<bool>(mapTabOpenSearchProvider, (prev, openSearch) {
      if (openSearch && widget.embeddedInShell && mounted) {
        ref.read(mapTabOpenSearchProvider.notifier).state = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showSearchAndAddDialog();
        });
      }
    });

    final state = ref.watch(rotaProvider);
    final basemap = ref.watch(mapSettingsProvider).basemap;
    final paradas = state.paradas;
    final visibleParadas = _filteredParadas(paradas);
    final rota = state.rota;
    final routeOptimized = rota?.otimizada == true;
    final dur = routeOptimized ? (rota?.duracaoMinutos ?? 0) : 0;
    final h = dur ~/ 60;
    final m = dur % 60;
    final dist = routeOptimized
        ? (rota?.distanciaKm ?? 0).toStringAsFixed(1).replaceAll('.', ',')
        : '';
    final isPro = ref.watch(subscriptionProvider).isPro;
    final showOsrmRoute = isPro && routeOptimized;
    final totalParadas = state.totalParadas;
    final totalPacotes = state.totalPacotes;
    final routeTotalsLabel = totalPacotes == totalParadas
        ? '$totalParadas paradas'
        : '$totalParadas paradas · $totalPacotes pacotes';
    final allowManualAdd = state.allowManualParadaEntry;
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

    final content = SafeArea(
        bottom: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: RouteMap(
                paradas: paradas,
                routePoints: showOsrmRoute ? state.routePoints : const [],
                allowRoutePolylines: showOsrmRoute,
                driverPosition: state.driverPosition,
                highlightStop: _selectedParadaId == null &&
                        state.navigationTargetParadaId == null &&
                        _optimized
                    ? 1
                    : null,
                selectedParadaId:
                    _selectedParadaId ?? (routeOptimized ? state.navigationTargetParadaId : null),
                mapController: _mapController,
                onParadaTap: _openParada,
                basemap: basemap,
                hideCompletedStops: false,
                showStopCallouts: false,
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
                    final sheetState = ref.watch(rotaProvider);
                    final sheetParadas = sheetState.paradas;
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
                            child: selected != null &&
                                    _panelMode == RouteMapPanelMode.list
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
                                            selectedColumns: sheetState.selectedColumns,
                                            stopIdDisplay: mapSettings.stopIdDisplay,
                                            emphasizedStopHeader: true,
                                            omitAddressAndPackageTiles: true,
                                            hideActionBar: true,
                                            onClose: () => setState(() => _selectedParadaId = null),
                                            onEdit: () => _editParada(selected),
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
                                : CustomScrollView(
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
                            onChanged: (v) => setState(() => _searchQuery = v),
                            onScan: null,
                            onMic: _searchRouteByVoice,
                            onMore: _openRouteOptions,
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
                                        onChanged: (v) => setState(() => _searchQuery = v),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
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
                          if (state.driverPosition != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Motorista: ${state.driverPosition!.latitude.toStringAsFixed(5)}, '
                                '${state.driverPosition!.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(color: AppColors.orange, fontSize: 11),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: state.useGpsOrigin,
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
                              subtitle: state.driverPosition != null
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
                                    ],
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
                                onOptimize: _otimizar,
                                onUseImportOrder: _useImportOrder,
                                onStart: () async {
                                  final st = ref.read(rotaProvider);
                                  await ref.read(rotaProvider.notifier).confirmRoute();
                                  MapTilePrefetch.prefetchAllBasemapsForRoute(
                                    paradas: st.paradas,
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
                final size = _sheetController.isAttached ? _sheetController.size : 0.4;
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
