import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:rota_prime/config/license_public_key.dart';
import 'package:rota_prime/services/device_id_service.dart';
import 'package:rota_prime/utils/license_input_format.dart';

class LicenseValidation {
  LicenseValidation({
    required this.valid,
    this.buyerName,
    this.reason,
  });

  final bool valid;
  final String? buyerName;
  final String? reason;
}

/// Licença assinada offline: payload.base64url + '.' + assinatura.base64url
class OfflineLicenseService {
  static final _algo = Ed25519();

  static Future<LicenseValidation> validateToken(String rawToken) async {
    if (rawToken.trim().isEmpty) {
      return LicenseValidation(valid: false, reason: 'Cole a chave enviada pelo suporte');
    }

    if (kLicensePublicKeyBase64 == 'REPLACE_AFTER_KEYGEN') {
      return LicenseValidation(
        valid: false,
        reason: 'App ainda sem chave pública (dev: rode license_keygen.dart)',
      );
    }

    LicenseValidation? last;
    for (final token in licenseTokenCandidates(rawToken)) {
      last = await _validateNormalizedToken(token);
      if (last.valid) return last;
      if (last.reason != null &&
          last.reason != 'Assinatura inválida' &&
          last.reason != 'Licença corrompida' &&
          last.reason != 'Formato de licença inválido') {
        return last;
      }
    }
    return last ??
        LicenseValidation(valid: false, reason: 'Licença inválida. Cole a chave completa.');
  }

  static Future<LicenseValidation> _validateNormalizedToken(String token) async {
    if (token.isEmpty) {
      return LicenseValidation(valid: false, reason: 'Licença vazia');
    }

    final dot = token.lastIndexOf('.');
    if (dot <= 0 || dot >= token.length - 1) {
      return LicenseValidation(valid: false, reason: 'Formato de licença inválido');
    }

    final payloadB64 = token.substring(0, dot);
    final sigB64 = token.substring(dot + 1);

    List<int> payloadBytes;
    List<int> sigBytes;
    try {
      payloadBytes = base64Url.decode(_padBase64Url(payloadB64));
      sigBytes = base64Url.decode(_padBase64Url(sigB64));
    } catch (_) {
      return LicenseValidation(valid: false, reason: 'Licença corrompida');
    }

    SimplePublicKey publicKey;
    try {
      final pubRaw = base64Url.decode(_padBase64Url(kLicensePublicKeyBase64));
      publicKey = SimplePublicKey(pubRaw, type: KeyPairType.ed25519);
    } catch (_) {
      return LicenseValidation(valid: false, reason: 'Chave pública inválida no app');
    }

    final signature = Signature(sigBytes, publicKey: publicKey);
    final ok = await _algo.verify(payloadBytes, signature: signature);
    if (!ok) {
      return LicenseValidation(valid: false, reason: 'Assinatura inválida');
    }

    final parsed = _parsePayload(payloadBytes);
    if (parsed == null) {
      return LicenseValidation(valid: false, reason: 'Conteúdo da licença inválido');
    }

    if (parsed.plan != 'pro') {
      return LicenseValidation(valid: false, reason: 'Plano não reconhecido');
    }

    final licensedDevice = parsed.deviceId;
    if (licensedDevice.isEmpty) {
      return LicenseValidation(valid: false, reason: 'Licença sem aparelho');
    }

    final thisDevice = (await DeviceIdService.hardwareId()).toLowerCase();
    if (licensedDevice != thisDevice) {
      return LicenseValidation(
        valid: false,
        reason: 'Licença de outro aparelho. Copie seu ID em Configurações e envie ao suporte pelo WhatsApp',
      );
    }

    final buyer = parsed.buyerName;
    return LicenseValidation(valid: true, buyerName: buyer?.isNotEmpty == true ? buyer : null);
  }

  static _PayloadFields? _parsePayload(List<int> payloadBytes) {
    final text = utf8.decode(payloadBytes);
    if (text.startsWith('2|')) {
      final parts = text.split('|');
      if (parts.length >= 4 && parts[1] == 'pro') {
        return _PayloadFields(
          plan: parts[1],
          deviceId: parts[2].trim().toLowerCase(),
          buyerName: parts.sublist(3).join('|').trim(),
        );
      }
    }

    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return _PayloadFields(
        plan: (json['plan'] as String?) ?? '',
        deviceId: ((json['did'] as String?) ?? '').trim().toLowerCase(),
        buyerName: (json['buyer'] as String?)?.trim(),
      );
    } catch (_) {
      return null;
    }
  }

  static String _padBase64Url(String input) {
    final mod = input.length % 4;
    if (mod == 0) return input;
    return input + '=' * (4 - mod);
  }
}

class _PayloadFields {
  _PayloadFields({
    required this.plan,
    required this.deviceId,
    this.buyerName,
  });

  final String plan;
  final String deviceId;
  final String? buyerName;
}
