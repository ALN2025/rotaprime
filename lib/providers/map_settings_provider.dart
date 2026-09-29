import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/services/settings_persistence.dart';

enum NavAppPreference { wazeFirst, googleMapsFirst, askEachTime }

enum StopSidePreference { anySide, leftSide, rightSide }

enum VehicleType { car, motorcycle, truck }

enum StopIdDisplay { modernByRoute, numericOnly }

class MapSettingsState {
  const MapSettingsState({
    this.basemap = MapBasemap.streets,
    this.basemapUserPicked = false,
    this.avoidTolls = true,
    this.navBubble = true,
    this.themeDark = true,
    this.navApp = NavAppPreference.wazeFirst,
    this.stopSide = StopSidePreference.anySide,
    this.avgStopMinutes = 1,
    this.vehicleType = VehicleType.car,
    this.stopIdDisplay = StopIdDisplay.modernByRoute,
  });

  final MapBasemap basemap;
  /// Usuário escolheu Ruas/Escuro no menu de camadas (trial e PRO pagos).
  final bool basemapUserPicked;
  final bool avoidTolls;
  final bool navBubble;
  final bool themeDark;
  final NavAppPreference navApp;
  final StopSidePreference stopSide;
  final int avgStopMinutes;
  final VehicleType vehicleType;
  final StopIdDisplay stopIdDisplay;

  String get navAppLabel => switch (navApp) {
        NavAppPreference.wazeFirst => 'Waze (depois Google Maps)',
        NavAppPreference.googleMapsFirst => 'Google Maps (depois Waze)',
        NavAppPreference.askEachTime => 'Perguntar ao navegar',
      };

  String get stopSideLabel => switch (stopSide) {
        StopSidePreference.anySide => 'Qualquer lado do veículo',
        StopSidePreference.leftSide => 'Lado esquerdo',
        StopSidePreference.rightSide => 'Lado direito',
      };

  String get vehicleTypeLabel => switch (vehicleType) {
        VehicleType.car => 'Carro',
        VehicleType.motorcycle => 'Moto',
        VehicleType.truck => 'Caminhão',
      };

  String get stopIdLabel => switch (stopIdDisplay) {
        StopIdDisplay.modernByRoute => 'Moderno e por ordem de rota',
        StopIdDisplay.numericOnly => 'Somente número da parada',
      };

  MapSettingsState copyWith({
    MapBasemap? basemap,
    bool? basemapUserPicked,
    bool? avoidTolls,
    bool? navBubble,
    bool? themeDark,
    NavAppPreference? navApp,
    StopSidePreference? stopSide,
    int? avgStopMinutes,
    VehicleType? vehicleType,
    StopIdDisplay? stopIdDisplay,
  }) {
    return MapSettingsState(
      basemap: basemap ?? this.basemap,
      basemapUserPicked: basemapUserPicked ?? this.basemapUserPicked,
      avoidTolls: avoidTolls ?? this.avoidTolls,
      navBubble: navBubble ?? this.navBubble,
      themeDark: themeDark ?? this.themeDark,
      navApp: navApp ?? this.navApp,
      stopSide: stopSide ?? this.stopSide,
      avgStopMinutes: avgStopMinutes ?? this.avgStopMinutes,
      vehicleType: vehicleType ?? this.vehicleType,
      stopIdDisplay: stopIdDisplay ?? this.stopIdDisplay,
    );
  }
}

class MapSettingsNotifier extends StateNotifier<MapSettingsState> {
  MapSettingsNotifier(this._ref) : super(const MapSettingsState()) {
    if (state.basemap == MapBasemap.standard) {
      state = state.copyWith(basemap: MapBasemap.streets);
    }
  }

  final Ref _ref;

  void _persistLater() => Future.microtask(() => persistAllSettings(_ref));

  void applyFromStorage(MapSettingsState saved) {
    state = saved.copyWith(basemap: MapBasemap.normalizeSaved(saved.basemap));
  }

  void setBasemap(MapBasemap value, {bool userInitiated = true}) {
    state = state.copyWith(
      basemap: MapBasemap.normalizeSaved(value),
      basemapUserPicked: userInitiated ? true : state.basemapUserPicked,
    );
    _persistLater();
  }

  /// Volta para Ruas se o plano não inclui mapa escuro.
  void clampToPlanAccess(bool isPro) {
    final fixed = MapBasemap.effectiveForPlan(state.basemap, isPro: isPro);
    if (fixed != state.basemap) {
      state = state.copyWith(basemap: fixed);
      _persistLater();
    }
  }

  /// Grátis: só Ruas. Trial: mantém escolha. PRO licenciado/mensal: Escuro padrão até o usuário mudar.
  void syncBasemapWithPlan(SubscriptionState sub) {
    switch (sub.accessKind) {
      case PlanAccessKind.free:
        clampToPlanAccess(false);
        return;
      case PlanAccessKind.trialPro:
        clampToPlanAccess(true);
        return;
      case PlanAccessKind.licensedPro:
      case PlanAccessKind.subscriptionPro:
        clampToPlanAccess(true);
        if (!state.basemapUserPicked && state.basemap != MapBasemap.dark) {
          state = state.copyWith(basemap: MapBasemap.dark);
          _persistLater();
        }
        return;
    }
  }

  void setAvoidTolls(bool value) {
    state = state.copyWith(avoidTolls: value);
    _persistLater();
  }

  void setNavBubble(bool value) {
    state = state.copyWith(navBubble: value);
    _persistLater();
  }

  void setNavApp(NavAppPreference value) {
    state = state.copyWith(navApp: value);
    _persistLater();
  }

  void setStopSide(StopSidePreference value) {
    state = state.copyWith(stopSide: value);
    _persistLater();
  }

  void setAvgStopMinutes(int value) {
    state = state.copyWith(avgStopMinutes: value);
    _persistLater();
  }

  void setVehicleType(VehicleType value) {
    state = state.copyWith(vehicleType: value);
    _persistLater();
  }

  void setStopIdDisplay(StopIdDisplay value) {
    state = state.copyWith(stopIdDisplay: value);
    _persistLater();
  }
}

final mapSettingsProvider =
    StateNotifierProvider<MapSettingsNotifier, MapSettingsState>(
  (ref) => MapSettingsNotifier(ref),
);
