import 'package:rota_prime/config/license_online_config.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/services/device_id_service.dart';
import 'package:rota_prime/services/online_license_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefProUntilMs = 'rota_prime_pro_until_ms';
const _prefProUntilFetchedMs = 'rota_prime_pro_until_fetched_ms';
const _prefProUntilDeviceId = 'rota_prime_pro_until_device_id';

/// PRO mensal via Mercado Pago — validade em `pro_until` no GitHub (só após pagamento).
class SubscriptionProUntilPolicy {
  static Future<SubscriptionState> mergeOnlineSubscription(
    SubscriptionState base,
    SharedPreferences prefs, {
    bool bustCache = false,
  }) async {
    if (base.isLicensedPro) return base;

    final revoked = await OnlineLicenseService.isDeviceRevokedOnline();
    if (revoked == true) {
      await _clearCachedUntil(prefs);
      return base;
    }

    final deviceId = (await DeviceIdService.hardwareId()).trim().toLowerCase();
    final cachedDevice = prefs.getString(_prefProUntilDeviceId)?.trim().toLowerCase();

    if (prefs.getInt(_prefProUntilMs) != null &&
        (cachedDevice == null || cachedDevice.isEmpty || cachedDevice != deviceId)) {
      await _clearCachedUntil(prefs);
    } else if (cachedDevice != null &&
        cachedDevice.isNotEmpty &&
        cachedDevice != deviceId) {
      await _clearCachedUntil(prefs);
    }

    final lookup = await OnlineLicenseService.lookupProSubscriptionUntil(
      deviceId: deviceId,
      bustCache: bustCache,
    );

    if (lookup.serverResponded) {
      final untilUtc = lookup.untilUtc;
      if (untilUtc != null && _isActive(untilUtc)) {
        await prefs.setInt(_prefProUntilMs, untilUtc.millisecondsSinceEpoch);
        await prefs.setInt(_prefProUntilFetchedMs, DateTime.now().millisecondsSinceEpoch);
        await prefs.setString(_prefProUntilDeviceId, deviceId);
        return base.copyWith(proSubscriptionUntil: untilUtc.toLocal());
      }
      await _clearCachedUntil(prefs);
      return base.copyWith(clearProSubscriptionUntil: true);
    }

    final cachedMs = prefs.getInt(_prefProUntilMs);
    final fetchedMs = prefs.getInt(_prefProUntilFetchedMs);
    if (cachedMs != null &&
        fetchedMs != null &&
        cachedDevice != null &&
        cachedDevice == deviceId) {
      final cached = DateTime.fromMillisecondsSinceEpoch(cachedMs, isUtc: true);
      final fetched = DateTime.fromMillisecondsSinceEpoch(fetchedMs);
      final graceEnd = cached.add(Duration(days: kLicenseOnlineGraceDays));
      final offlineGraceOk =
          DateTime.now().difference(fetched) <= Duration(days: kLicenseOnlineGraceDays);
      if (offlineGraceOk && DateTime.now().toUtc().isBefore(graceEnd)) {
        return base.copyWith(proSubscriptionUntil: cached.toLocal());
      }
    }

    await _clearCachedUntil(prefs);
    return base.copyWith(clearProSubscriptionUntil: true);
  }

  static bool _isActive(DateTime untilUtc) {
    return DateTime.now().toUtc().isBefore(untilUtc);
  }

  static Future<void> clearCachedProUntil(SharedPreferences prefs) async {
    await _clearCachedUntil(prefs);
  }

  static Future<void> _clearCachedUntil(SharedPreferences prefs) async {
    await prefs.remove(_prefProUntilMs);
    await prefs.remove(_prefProUntilFetchedMs);
    await prefs.remove(_prefProUntilDeviceId);
  }
}
