import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/services/device_id_service.dart';
import 'package:rota_prime/services/online_license_service.dart';

/// Mensagem após «Já paguei — sincronizar» (lista online no GitHub).
Future<String> planSyncSnackBarMessage(WidgetRef ref) async {
  final sub = ref.read(subscriptionProvider);
  if (sub.isLicensedPro) {
    return 'Plano: ${sub.planLabel}';
  }
  if (sub.hasActiveSubscription) {
    return 'Plano: ${sub.planLabel} · ${sub.planStatusLine}';
  }
  if (sub.isTrialActive) {
    return 'Plano: ${sub.planLabel} · ${sub.planStatusLine}';
  }
  if (sub.accessKind == PlanAccessKind.free) {
    final trialUsed = await OnlineLicenseService.isDeviceTrialUsedOnlineWithRetry(
      bustCache: true,
    );
    if (trialUsed == false) {
      return 'Trial disponível neste aparelho — feche e abra o app ou aguarde alguns segundos.';
    }
  }

  final deviceId = (await DeviceIdService.hardwareId()).trim().toLowerCase();
  final untilUtc = await OnlineLicenseService.fetchProSubscriptionUntil(
    deviceId: deviceId,
    bustCache: true,
  );

  if (untilUtc != null && !DateTime.now().toUtc().isBefore(untilUtc)) {
    return 'PRO mensal expirou. Renove no Mercado Pago e sincronize de novo.';
  }

  final idHint = deviceId.length > 10
      ? '${deviceId.substring(0, 6)}…${deviceId.substring(deviceId.length - 6)}'
      : deviceId;

  return 'Ainda Grátis — o servidor não tem PRO para o ID $idHint. '
      'Use sempre «Cartão/Pix» neste app (ID na URL). '
      'Aguarde 2–5 min após pagar. Se continuar, envie este ID ao suporte.';
}
