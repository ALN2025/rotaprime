import 'package:package_info_plus/package_info_plus.dart';
import 'package:rota_prime/services/subscription_pro_until_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kPrefInstallBoundMs = 'rota_prime_install_bound_ms';
const kPrefTrialStartMs = 'rota_prime_pro_trial_start_ms';
const kPrefTrialRegisteredOnline = 'rota_prime_trial_registered_online';

/// Desinstalar + instalar de novo muda [PackageInfo.installTime]; prefs antigas
/// (backup Google) não podem forçar “trial já usado” ou PRO mensal fantasma.
Future<void> syncSubscriptionInstallSession(SharedPreferences prefs) async {
  try {
    final info = await PackageInfo.fromPlatform();
    final installMs = info.installTime?.millisecondsSinceEpoch;
    if (installMs == null) return;

    final stored = prefs.getInt(kPrefInstallBoundMs);
    if (stored == installMs) return;

    await prefs.remove(kPrefTrialStartMs);
    await prefs.setBool(kPrefTrialRegisteredOnline, false);
    await SubscriptionProUntilPolicy.clearCachedProUntil(prefs);
    await prefs.setInt(kPrefInstallBoundMs, installMs);
  } catch (_) {}
}
