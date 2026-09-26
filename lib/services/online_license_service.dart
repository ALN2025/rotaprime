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



  /// Registra aparelho na lista online (Apps Script → GitHub). Falha silenciosa se URL vazia.

  static Future<bool> registerTrialUsedDevice(String deviceId) async {

    final url = kTrialRegisterUrl.trim();

    if (url.isEmpty) return false;

    final id = deviceId.trim().toLowerCase();

    if (id.isEmpty) return false;

    try {

      final res = await http

          .post(

            Uri.parse(url),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({

              'device_id': id,

              'register_secret': kTrialRegisterSecret,

            }),

          )

          .timeout(const Duration(seconds: 8));

      return res.statusCode >= 200 && res.statusCode < 300;

    } catch (_) {

      return false;

    }

  }

}


