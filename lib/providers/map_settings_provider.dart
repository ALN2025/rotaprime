import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/services/settings_persistence.dart';

enum NavAppPreference { wazeFirst, googleMapsFirst, askEachTime }

enum StopSidePreference { anySide, leftSide, rightSide }

enum VehicleType { car, motorcycle, truck }

enum StopIdDisplay { modernByRoute, numericOnly }

class MapSettingsState {
  const MapSettingsState({
    this.basemap = MapBasemap.streets,
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
  MapSettingsNotifier(this._ref) : super(const MapSettingsState());

  final Ref _ref;

  void _persistLater() => Future.microtask(() => persistAllSettings(_ref));

  void applyFromStorage(MapSettingsState saved) => state = saved;

  void setBasemap(MapBasemap value) {
    state = state.copyWith(basemap: value);
    _persistLater();
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
