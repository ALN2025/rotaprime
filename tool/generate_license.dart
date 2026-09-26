// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:rota_prime/utils/license_input_format.dart';

/// Gera licença PRO (chave única com traços) — uso interno DEV ALN.
///
/// Uso:
///   dart run tool/generate_license.dart --buyer "Maria Silva" --device abc123...
Future<void> main(List<String> args) async {
  String? buyer = Platform.environment['ROTA_BUYER']?.trim();
  String? device = Platform.environment['ROTA_DEVICE']?.trim();

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--buyer' && i + 1 < args.length) {
      buyer = args[++i];
    } else if (args[i] == '--device' && i + 1 < args.length) {
      device = args[++i];
    }
  }

  if (device == null || device.trim().isEmpty) {
    print('Informe o ID do aparelho (Configurações no app → ID do aparelho).');
    print('');
    print('Exemplo:');
    print('  dart run tool/generate_license.dart --buyer "Cliente" --device ID_DO_CELULAR');
    exit(1);
  }

  final privateFile = File('license_keys/private.key');
  if (!privateFile.existsSync()) {
    print('Arquivo license_keys/private.key não encontrado.');
    print('Rode primeiro: dart run tool/license_keygen.dart');
    exit(1);
  }

  final algo = Ed25519();
  final privateRaw = base64Url.decode(_pad(privateFile.readAsStringSync().trim()));
  final seed = privateRaw.length >= 32 ? privateRaw.sublist(0, 32) : privateRaw;
  final keyPair = await algo.newKeyPairFromSeed(seed);

  final deviceId = device.trim().toLowerCase();
  final buyerName = buyer ?? 'Licenciado';
  final payloadBytes = utf8.encode('2|pro|$deviceId|$buyerName');
  final signature = await algo.sign(payloadBytes, keyPair: keyPair);

  final payloadB64 = base64Url.encode(payloadBytes).replaceAll('=', '');
  final sigB64 = base64Url.encode(signature.bytes).replaceAll('=', '');
  final token = '$payloadB64.$sigB64';
  final keyDashed = formatLicenseDashed(token);

  print('');
  print('=== CHAVE PRO (envie ao comprador) ===');
  print(keyDashed);
  print('');
  print('Comprador: $buyerName');
  print('Aparelho: $deviceId');
  print('Referencia: ALN-${licenseReferenceCode(deviceId)}');
  print('');
  print('@@LICENSE_KEY@@$keyDashed');

  final dir = Directory('license_keys');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final saved = StringBuffer()
    ..writeln('Comprador: $buyerName')
    ..writeln('Aparelho: $deviceId')
    ..writeln('Referencia: ALN-${licenseReferenceCode(deviceId)}')
    ..writeln('Gerado em: ${DateTime.now().toIso8601String()}')
    ..writeln()
    ..writeln('CHAVE PRO (cole em Configuracoes → Assinatura):')
    ..writeln(keyDashed);

  final dirPath = 'license_keys';
  var fileName = licenseClientFileName(buyerName, deviceId);
  var out = File('$dirPath/$fileName');
  if (out.existsSync()) {
    fileName = licenseClientFileName(buyerName, deviceId, fileAlreadyExists: true);
    out = File('$dirPath/$fileName');
  }
  await out.writeAsString(saved.toString());
  await File('$dirPath/ultima_licenca.txt').writeAsString(saved.toString());

  print('');
  print('Salvo em: ${out.path}');
  print('@@LICENSE_FILE@@${out.path.replaceAll(r'\', '/')}');
}

String _pad(String input) {
  final mod = input.length % 4;
  if (mod == 0) return input;
  return input + '=' * (4 - mod);
}
