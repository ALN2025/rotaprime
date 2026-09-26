import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:rota_prime/config/plan_limits.dart';

import 'package:shared_preferences/shared_preferences.dart';



import 'package:rota_prime/services/device_id_service.dart';

import 'package:rota_prime/services/offline_license_service.dart';

import 'package:rota_prime/services/online_license_service.dart';



const _prefIsPro = 'rota_prime_is_pro';



const _prefLicenseToken = 'rota_prime_license_token';



const _prefLicenseBuyer = 'rota_prime_license_buyer';

const _prefLicenseOnlineCheckMs = 'rota_prime_license_online_ms';

const _prefLicenseRevokedNotice = 'rota_prime_license_revoked_notice';

const _prefTrialStartMs = 'rota_prime_pro_trial_start_ms';

const _prefTrialRegisteredOnline = 'rota_prime_trial_registered_online';



enum PlanAccessKind { free, trialPro, licensedPro }



class SubscriptionState {

  const SubscriptionState({

    this.isLicensedPro = false,

    this.trialStartedAt,

    this.buyerName,

    this.pendingRevokedNotice = false,

  });



  final bool isLicensedPro;

  final DateTime? trialStartedAt;

  final String? buyerName;

  final bool pendingRevokedNotice;



  bool get isTrialActive {

    if (isLicensedPro || trialStartedAt == null) return false;

    final elapsed = DateTime.now().difference(trialStartedAt!).inDays;

    return elapsed < PlanLimits.proTrialDays;

  }



  /// Recursos PRO (otimização, linha laranja, etc.).

  bool get isPro => isLicensedPro || isTrialActive;



  PlanAccessKind get accessKind {

    if (isLicensedPro) return PlanAccessKind.licensedPro;

    if (isTrialActive) return PlanAccessKind.trialPro;

    return PlanAccessKind.free;

  }



  int get trialDaysRemaining {

    if (!isTrialActive || trialStartedAt == null) return 0;

    final elapsed = DateTime.now().difference(trialStartedAt!).inDays;

    return PlanLimits.proTrialDays - elapsed;

  }



  String get planLabel => switch (accessKind) {

        PlanAccessKind.licensedPro => 'ROTA PRIME PRO',

        PlanAccessKind.trialPro => 'Trial PRO',

        PlanAccessKind.free => 'Gratuito',

      };



  String get planStatusLine => switch (accessKind) {

        PlanAccessKind.licensedPro =>

          buyerName != null && buyerName!.isNotEmpty

              ? 'Licenciado: $buyerName'

              : 'Licença PRO neste aparelho',

        PlanAccessKind.trialPro =>

          'Trial grátis: faltam $trialDaysRemaining dia${trialDaysRemaining == 1 ? '' : 's'} · depois plano Grátis',

        PlanAccessKind.free =>

          'Plano Grátis: até ${PlanLimits.freeMaxDeliveriesPerRoute} entregas/rota (planilha ou manual) · chave PRO',

      };



  SubscriptionState copyWith({

    bool? isLicensedPro,

    DateTime? trialStartedAt,

    String? buyerName,

    bool? pendingRevokedNotice,

  }) {

    return SubscriptionState(

      isLicensedPro: isLicensedPro ?? this.isLicensedPro,

      trialStartedAt: trialStartedAt ?? this.trialStartedAt,

      buyerName: buyerName ?? this.buyerName,

      pendingRevokedNotice: pendingRevokedNotice ?? this.pendingRevokedNotice,

    );

  }

}



class SubscriptionNotifier extends StateNotifier<SubscriptionState> {

  SubscriptionNotifier() : super(const SubscriptionState());



  Future<void> load() async {

    final prefs = await SharedPreferences.getInstance();



    final token = prefs.getString(_prefLicenseToken);



    if (token != null && token.isNotEmpty) {

      final check = await OfflineLicenseService.validateToken(token);



      if (check.valid) {

        state = SubscriptionState(

          isLicensedPro: true,

          buyerName: check.buyerName,

          trialStartedAt: _readTrialStart(prefs),

        );

        await _refreshOnlineLicenseStatus();

        return;

      }



      await _clearLicense(prefs);

    }



    final legacyPro = prefs.getBool(_prefIsPro) ?? false;

    final revokedNotice = prefs.getBool(_prefLicenseRevokedNotice) ?? false;



    if (legacyPro) {

      state = SubscriptionState(

        isLicensedPro: true,

        pendingRevokedNotice: revokedNotice,

        trialStartedAt: _readTrialStart(prefs),

      );

      return;

    }



    state = await _stateWithTrialForFreeUser(prefs, revokedNotice: revokedNotice);

  }



  /// Depois de liberar trial no script GitHub — Configurações → sincronizar plano.

  Future<void> reloadPlanFromServer() async {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_prefLicenseToken);

    if (token != null && token.isNotEmpty) {

      await load();

      return;

    }

    if (prefs.getBool(_prefIsPro) ?? false) {

      await load();

      return;

    }

    final revokedNotice = prefs.getBool(_prefLicenseRevokedNotice) ?? false;

    state = await _stateWithTrialForFreeUser(

      prefs,

      revokedNotice: revokedNotice,

      bustCache: true,

    );

  }



  Future<void> acknowledgeRevokedNotice() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_prefLicenseRevokedNotice, false);

    state = state.copyWith(pendingRevokedNotice: false);

  }



  Future<({bool ok, String? error})> tryActivateLicense(String raw) async {

    final token = raw.trim();



    final check = await OfflineLicenseService.validateToken(token);



    if (!check.valid) {

      return (ok: false, error: check.reason ?? 'Licença inválida');

    }



    final prefs = await SharedPreferences.getInstance();



    await prefs.setString(_prefLicenseToken, token);



    await prefs.setString(_prefLicenseBuyer, check.buyerName ?? '');



    await prefs.setBool(_prefIsPro, true);



    state = SubscriptionState(

      isLicensedPro: true,

      buyerName: check.buyerName,

      trialStartedAt: _readTrialStart(prefs),

    );

    await _refreshOnlineLicenseStatus();

    if (state.pendingRevokedNotice) {

      return (ok: false, error: 'Licença revogada — fale com o suporte.');

    }

    if (!state.isLicensedPro) {

      return (ok: false, error: 'Não foi possível ativar o PRO neste aparelho.');

    }

    await prefs.setBool(_prefLicenseRevokedNotice, false);

    state = state.copyWith(pendingRevokedNotice: false);



    return (ok: true, error: null);

  }



  Future<void> _refreshOnlineLicenseStatus() async {

    final revoked = await OnlineLicenseService.isDeviceRevokedOnline();

    final prefs = await SharedPreferences.getInstance();

    if (revoked == null) return;

    await prefs.setInt(_prefLicenseOnlineCheckMs, DateTime.now().millisecondsSinceEpoch);

    if (revoked) {

      await _markLicenseRevoked(prefs);

    }

  }



  Future<void> _markLicenseRevoked(SharedPreferences prefs) async {

    await _clearLicense(prefs);

    await prefs.setBool(_prefLicenseRevokedNotice, true);

    state = await _stateWithTrialForFreeUser(prefs, revokedNotice: true);

  }



  Future<bool> tryActivateKey(String raw) async {

    final result = await tryActivateLicense(raw);

    return result.ok;

  }



  Future<void> cancelPro() async {

    final prefs = await SharedPreferences.getInstance();



    await _clearLicense(prefs);



    state = await _stateWithTrialForFreeUser(prefs);

  }



  Future<void> _clearLicense(SharedPreferences prefs) async {

    await prefs.remove(_prefLicenseToken);



    await prefs.remove(_prefLicenseBuyer);



    await prefs.setBool(_prefIsPro, false);

  }



  DateTime? _readTrialStart(SharedPreferences prefs) {

    final ms = prefs.getInt(_prefTrialStartMs);

    if (ms == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(ms);

  }



  DateTime _expiredTrialStartAnchor() {

    return DateTime.now().subtract(Duration(days: PlanLimits.proTrialDays + 2));

  }



  SubscriptionState _stateWithExpiredTrial({required bool revokedNotice}) {

    final expired = _expiredTrialStartAnchor();

    return SubscriptionState(

      trialStartedAt: expired,

      pendingRevokedNotice: revokedNotice,

    );

  }



  Future<void> _registerTrialInBackground(String deviceId) async {

    final ok = await OnlineLicenseService.registerTrialUsedDevice(deviceId);

    if (!ok) return;

    final p = await SharedPreferences.getInstance();

    await p.setBool(_prefTrialRegisteredOnline, true);

  }



  Future<SubscriptionState> _startFreshTrial(

    SharedPreferences prefs, {

    required String deviceId,

    required bool revokedNotice,

  }) async {

    await prefs.setBool(_prefTrialRegisteredOnline, false);

    final startMs = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(_prefTrialStartMs, startMs);

    Future<void>(() => _registerTrialInBackground(deviceId));

    if (kDebugMode) {

      debugPrint('ROTA PRIME: Trial PRO iniciado (device $deviceId)');

    }

    return SubscriptionState(

      trialStartedAt: DateTime.fromMillisecondsSinceEpoch(startMs),

      pendingRevokedNotice: revokedNotice,

    );

  }



  bool _trialStillActive(DateTime started) {

    return DateTime.now().difference(started).inDays < PlanLimits.proTrialDays;

  }



  Future<SubscriptionState> _stateWithTrialForFreeUser(

    SharedPreferences prefs, {

    bool revokedNotice = false,

    bool bustCache = false,

  }) async {

    final deviceId = (await DeviceIdService.hardwareId()).trim().toLowerCase();

    final trialUsedOnline =

        await OnlineLicenseService.isDeviceTrialUsedOnline(bustCache: bustCache);



    // Liberado no script (ID removido de trial_used_device_ids) → trial novo.

    if (trialUsedOnline == false) {

      return _startFreshTrial(prefs, deviceId: deviceId, revokedNotice: revokedNotice);

    }



    if (trialUsedOnline == true) {

      await prefs.setBool(_prefTrialRegisteredOnline, true);

      final existingMs = prefs.getInt(_prefTrialStartMs);

      if (existingMs != null) {

        final started = DateTime.fromMillisecondsSinceEpoch(existingMs);

        if (_trialStillActive(started)) {

          return SubscriptionState(

            trialStartedAt: started,

            pendingRevokedNotice: revokedNotice,

          );

        }

      }

      // Trial já consumiu neste aparelho (lista online).

      final expired = _expiredTrialStartAnchor();

      await prefs.setInt(_prefTrialStartMs, expired.millisecondsSinceEpoch);

      return _stateWithExpiredTrial(revokedNotice: revokedNotice);

    }



    // Sem resposta do servidor (offline / timeout).

    var startMs = prefs.getInt(_prefTrialStartMs);

    final registeredOnline = prefs.getBool(_prefTrialRegisteredOnline) ?? false;



    if (startMs == null && registeredOnline) {

      return _stateWithExpiredTrial(revokedNotice: revokedNotice);

    }



    if (startMs == null) {

      return _startFreshTrial(prefs, deviceId: deviceId, revokedNotice: revokedNotice);

    }



    final started = DateTime.fromMillisecondsSinceEpoch(startMs);

    if (!_trialStillActive(started)) {

      return _stateWithExpiredTrial(revokedNotice: revokedNotice);

    }



    if (!registeredOnline) {

      Future<void>(() => _registerTrialInBackground(deviceId));

    }



    return SubscriptionState(

      trialStartedAt: started,

      pendingRevokedNotice: revokedNotice,

    );

  }

}



final subscriptionProvider =

    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {

  return SubscriptionNotifier();

});

