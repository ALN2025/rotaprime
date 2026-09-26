import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/services/user_prefs_service.dart';

const kLocalSettingsKey = 'local_device';

final _prefs = UserPrefsService();

Future<void> persistAllSettings(Ref ref) async {
  final map = ref.read(mapSettingsProvider);
  final rota = ref.read(rotaProvider);
  final data = _prefs.mapSettingsToJson(map)
    ..['selectedColumns'] = rota.selectedColumns.toList()
    ..['useGpsOrigin'] = rota.useGpsOrigin;
  await _prefs.save(kLocalSettingsKey, data);
}

Future<void> loadAllSettings(Ref ref) async {
  final json = await _prefs.load(kLocalSettingsKey);
  if (json == null) return;
  ref.read(mapSettingsProvider.notifier).applyFromStorage(
        _prefs.mapSettingsFromJson(json),
      );
  final cols = json['selectedColumns'];
  if (cols is List) {
    ref.read(rotaProvider.notifier).applySelectedColumns(
          cols.map((e) => e.toString()).toSet(),
          persist: false,
        );
  }
  final gps = json['useGpsOrigin'];
  if (gps is bool) {
    ref.read(rotaProvider.notifier).setUseGpsOrigin(gps, persist: false);
  }
}
