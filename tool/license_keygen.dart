// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

/// Gera par de chaves Ed25519 (rode UMA vez no seu PC).
/// Privada: license_keys/private.key (NÃO compartilhe)
/// Pública: atualiza lib/config/license_public_key.dart
Future<void> main() async {
  final algo = Ed25519();
  final keyPair = await algo.newKeyPair();
  final publicKey = await keyPair.extractPublicKey();
  final privateBytes = await keyPair.extractPrivateKeyBytes();
  final publicB64 = base64Url.encode(publicKey.bytes).replaceAll('=', '');

  final dir = Directory('license_keys');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File('license_keys/private.key').writeAsStringSync(base64Url.encode(privateBytes));

  final pubFile = File('lib/config/license_public_key.dart');
  pubFile.writeAsStringSync('''/// Chave pública Ed25519 (só verificação — a privada fica no seu PC em license_keys/).
/// Gere com: dart run tool/license_keygen.dart
const kLicensePublicKeyBase64 = '$publicB64';
''');

  print('OK: license_keys/private.key criado (guarde backup!)');
  print('OK: lib/config/license_public_key.dart atualizado');
  print('Próximo: gere licenças com dart run tool/generate_license.dart');
}
