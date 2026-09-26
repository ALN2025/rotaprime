import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Entrega em andamento: tela acordada, brilho baixo e toque para clarear.
class DeliveryCockpitService {
  DeliveryCockpitService._();

  static final DeliveryCockpitService instance = DeliveryCockpitService._();

  static const _dimBrightness = 0.22;
  static const _wakeBrightness = 0.92;
  static const _autoDimAfter = Duration(seconds: 75);

  double? _brightnessBefore;
  Timer? _autoDimTimer;
  bool _active = false;
  bool dimmed = true;
  final Listenable dimListenable = ValueNotifier<int>(0);

  bool get isActive => _active;

  void _notifyDimChanged() {
    (dimListenable as ValueNotifier<int>).value++;
  }

  Future<void> start() async {
    if (_active) return;
    _active = true;
    try {
      await WakelockPlus.enable();
    } catch (_) {}
    try {
      _brightnessBefore = await ScreenBrightness().application;
    } catch (_) {
      _brightnessBefore = null;
    }
    try {
      await wakeForInteraction();
    } catch (_) {
      dimmed = false;
      _notifyDimChanged();
    }
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    _autoDimTimer?.cancel();
    _autoDimTimer = null;
    await WakelockPlus.disable();
    await _restoreBrightness();
  }

  /// Enquanto o mapa está claro, reinicia o timer antes de escurecer de novo.
  void bumpAwakeTimer() {
    if (!_active || dimmed) return;
    _autoDimTimer?.cancel();
    _autoDimTimer = Timer(_autoDimAfter, () {
      unawaited(_applyDim());
    });
  }

  /// Toque na tela — clareia para o entregador se orientar.
  Future<void> wakeForInteraction() async {
    if (!_active) return;
    dimmed = false;
    _notifyDimChanged();
    _autoDimTimer?.cancel();
    try {
      await ScreenBrightness().setApplicationScreenBrightness(_wakeBrightness);
    } catch (_) {}
    _autoDimTimer = Timer(_autoDimAfter, () {
      unawaited(_applyDim());
    });
  }

  Future<void> _applyDim() async {
    if (!_active) return;
    dimmed = true;
    _notifyDimChanged();
    try {
      await ScreenBrightness().setApplicationScreenBrightness(_dimBrightness);
    } catch (_) {}
  }

  Future<void> _restoreBrightness() async {
    final prev = _brightnessBefore;
    if (prev == null) return;
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (_) {
      try {
        await ScreenBrightness().setApplicationScreenBrightness(prev);
      } catch (_) {}
    }
    _brightnessBefore = null;
  }
}
