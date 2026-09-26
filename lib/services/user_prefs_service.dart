import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';

class UserPrefsService {
  static String _key(String email) => 'rota_prime_prefs_${email.toLowerCase()}';

  Future<Map<String, dynamic>?> load(String email) async {
    if (email.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(email));
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String email, Map<String, dynamic> data) async {
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(email), jsonEncode(data));
  }

  MapSettingsState mapSettingsFromJson(Map<String, dynamic>? json) {
    if (json == null) return const MapSettingsState();
    MapBasemap basemap = MapBasemap.streets;
    final bm = json['basemap'] as String?;
    if (bm != null && bm != 'standard') {
      for (final v in MapBasemap.values) {
        if (v.name == bm) basemap = v;
      }
    }
    NavAppPreference navApp = NavAppPreference.wazeFirst;
    final na = json['navApp'] as String?;
    for (final v in NavAppPreference.values) {
      if (v.name == na) navApp = v;
    }
    StopSidePreference stopSide = StopSidePreference.anySide;
    final ss = json['stopSide'] as String?;
    for (final v in StopSidePreference.values) {
      if (v.name == ss) stopSide = v;
    }
    VehicleType vehicle = VehicleType.car;
    final vt = json['vehicleType'] as String?;
    for (final v in VehicleType.values) {
      if (v.name == vt) vehicle = v;
    }
    StopIdDisplay stopId = StopIdDisplay.modernByRoute;
    final sid = json['stopIdDisplay'] as String?;
    for (final v in StopIdDisplay.values) {
      if (v.name == sid) stopId = v;
    }
    return MapSettingsState(
      basemap: basemap,
      avoidTolls: json['avoidTolls'] as bool? ?? true,
      navBubble: json['navBubble'] as bool? ?? true,
      themeDark: json['themeDark'] as bool? ?? true,
      navApp: navApp,
      stopSide: stopSide,
      avgStopMinutes: json['avgStopMinutes'] as int? ?? 1,
      vehicleType: vehicle,
      stopIdDisplay: stopId,
    );
  }

  Map<String, dynamic> mapSettingsToJson(MapSettingsState s) {
    return {
      'basemap': s.basemap.name,
      'avoidTolls': s.avoidTolls,
      'navBubble': s.navBubble,
      'themeDark': s.themeDark,
      'navApp': s.navApp.name,
      'stopSide': s.stopSide.name,
      'avgStopMinutes': s.avgStopMinutes,
      'vehicleType': s.vehicleType.name,
      'stopIdDisplay': s.stopIdDisplay.name,
    };
  }
}
