import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Identificador estável do aparelho (para licença offline vinculada ao device).
class DeviceIdService {
  static final _plugin = DeviceInfoPlugin();

  static Future<String> hardwareId() async {
    if (kIsWeb) {
      return 'web-${sha256.convert(utf8.encode('rota-prime-web')).toString().substring(0, 16)}';
    }

    try {
      final android = await _plugin.androidInfo;
      final raw = android.id.trim();
      if (raw.isNotEmpty && raw != 'unknown') {
        return _hash(raw);
      }
    } catch (_) {}

    try {
      final ios = await _plugin.iosInfo;
      final raw = ios.identifierForVendor?.trim() ?? '';
      if (raw.isNotEmpty) {
        return _hash(raw);
      }
    } catch (_) {}

    return _hash('rota-prime-fallback');
  }

  static String _hash(String raw) {
    return sha256.convert(utf8.encode('rota-prime-v1|$raw')).toString().substring(0, 24);
  }
}
