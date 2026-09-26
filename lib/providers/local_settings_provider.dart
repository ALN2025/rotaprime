import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/services/settings_persistence.dart';

class LocalSettingsNotifier {
  LocalSettingsNotifier(this._ref);

  final Ref _ref;

  Future<void> load() => loadAllSettings(_ref);

  Future<void> save() => persistAllSettings(_ref);
}

final localSettingsProvider = Provider<LocalSettingsNotifier>((ref) {
  return LocalSettingsNotifier(ref);
});
