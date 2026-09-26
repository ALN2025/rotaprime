import 'package:flutter/services.dart';

/// Minimiza o app sem encerrar a activity (volta direto ao mapa).
class AppLifecycleBridge {
  AppLifecycleBridge._();

  static const _channel = MethodChannel('com.rotaprime/app_lifecycle');

  static Future<void> minimizeToBackground() async {
    try {
      await _channel.invokeMethod<void>('moveTaskToBack');
    } catch (_) {
      await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
    }
  }
}
