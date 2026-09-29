import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:rota_prime/config/license_online_config.dart';

import 'package:rota_prime/services/device_id_service.dart';



class OnlineLicenseService {

  OnlineLicenseService._();



  static Future<Map<String, dynamic>?> _fetchDevicePolicyJson({bool bustCache = false}) async {

    try {

      var url = kLicenseRevocationListUrl;

      if (bustCache) {

        final sep = url.contains('?') ? '&' : '?';

        url = '$url${sep}t=${DateTime.now().millisecondsSinceEpoch}';

      }

      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);

      if (json is! Map<String, dynamic>) return null;

      return json;

    } catch (_) {

      return null;

    }

  }



  static Set<String> _parseIdList(Object? raw) {

    if (raw is! List) return {};

    return raw.whereType<String>().map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toSet();

  }



  static Future<Set<String>?> fetchRevokedDeviceIds() async {

    final json = await _fetchDevicePolicyJson();

    if (json == null) return null;

    return _parseIdList(json['revoked_device_ids']);

  }



  /// IDs que já consumiram o trial PRO (anti-reinstalar APK).

  static Future<Set<String>?> fetchTrialUsedDeviceIds({bool bustCache = false}) async {

    final json = await _fetchDevicePolicyJson(bustCache: bustCache);

    if (json == null) return null;

    return _parseIdList(json['trial_used_device_ids']);

  }



  static Future<bool?> isDeviceRevokedOnline() async {

    final revoked = await fetchRevokedDeviceIds();

    if (revoked == null) return null;

    final device = (await DeviceIdService.hardwareId()).trim().toLowerCase();

    return revoked.contains(device);

  }



  static Future<bool?> isDeviceTrialUsedOnline({bool bustCache = false}) async {

    final used = await fetchTrialUsedDeviceIds(bustCache: bustCache);

    if (used == null) return null;

    final device = (await DeviceIdService.hardwareId()).trim().toLowerCase();

    return used.contains(device);

  }

  /// Várias tentativas — GitHub / rede instável na 1ª abertura após instalar.
  static Future<bool?> isDeviceTrialUsedOnlineWithRetry({
    int attempts = 4,
    bool bustCache = true,
  }) async {
    final max = attempts < 1 ? 1 : attempts;
    for (var i = 0; i < max; i++) {
      final v = await isDeviceTrialUsedOnline(bustCache: bustCache);
      if (v != null) return v;
      if (i < max - 1) {
        await Future<void>.delayed(Duration(milliseconds: 700 * (i + 1)));
      }
    }
    return null;
  }



  /// Registra aparelho na lista online (Apps Script → GitHub). Falha silenciosa se URL vazia.

  /// Data ISO 8601 UTC em que o PRO mensal expira (Mercado Pago → GitHub `pro_until`).
  static Future<DateTime?> fetchProSubscriptionUntil({
    String? deviceId,
    bool bustCache = false,
  }) async {
    final lookup = await lookupProSubscriptionUntil(
      deviceId: deviceId,
      bustCache: bustCache,
    );
    return lookup.untilUtc;
  }

  /// [serverResponded] false = offline/timeout — caller may usar cache local amarrado ao ID.
  static Future<({DateTime? untilUtc, bool serverResponded})> lookupProSubscriptionUntil({
    String? deviceId,
    bool bustCache = false,
  }) async {
    final json = await _fetchDevicePolicyJson(bustCache: bustCache);
    if (json == null) {
      return (untilUtc: null, serverResponded: false);
    }
    final map = json['pro_until'];
    if (map is! Map) {
      return (untilUtc: null, serverResponded: true);
    }
    final id = (deviceId ?? (await DeviceIdService.hardwareId())).trim().toLowerCase();
    if (id.isEmpty) {
      return (untilUtc: null, serverResponded: true);
    }
    final raw = map[id];
    if (raw is! String || raw.trim().isEmpty) {
      return (untilUtc: null, serverResponded: true);
    }
    return (untilUtc: DateTime.tryParse(raw.trim())?.toUtc(), serverResponded: true);
  }

  static Future<bool> registerTrialUsedDevice(String deviceId) async {
    return _postRegisterAction(
      deviceId: deviceId,
      body: {
        'device_id': deviceId.trim().toLowerCase(),
        'register_secret': kTrialRegisterSecret,
      },
    );
  }

  /// Lista no GitHub após ativar chave PRO (painel admin → licensed_pro_devices).
  static Future<bool> registerLicensedProDevice(
    String deviceId, {
    String? buyerName,
  }) async {
    final id = deviceId.trim().toLowerCase();
    if (id.isEmpty) return false;
    final buyer = buyerName?.trim();
    return _postRegisterAction(
      deviceId: id,
      body: {
        'action': 'register_licensed_pro',
        'device_id': id,
        'register_secret': kTrialRegisterSecret,
        if (buyer != null && buyer.isNotEmpty) 'buyer': buyer,
      },
    );
  }

  static Future<bool> _postRegisterAction({
    required String deviceId,
    required Map<String, dynamic> body,
  }) async {
    final url = kTrialRegisterUrl.trim();
    if (url.isEmpty) return false;
    if (deviceId.trim().isEmpty) return false;
    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}


