import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Evita importar o mesmo PDF/planilha duas vezes na mesma rota.
class RomaneioImportRegistry {
  RomaneioImportRegistry._();

  static String fingerprint(Uint8List bytes) => sha256.convert(bytes).toString();

  static String _prefKey(int rotaId) => 'rota_prime_romaneio_fp_$rotaId';

  static Future<List<String>> fingerprintsForRota(int rotaId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey(rotaId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<String>().toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> containsFile(int rotaId, Uint8List bytes) async {
    final fp = fingerprint(bytes);
    final list = await fingerprintsForRota(rotaId);
    return list.contains(fp);
  }

  static Future<void> registerFile(int rotaId, Uint8List bytes) async {
    final fp = fingerprint(bytes);
    final prefs = await SharedPreferences.getInstance();
    final list = await fingerprintsForRota(rotaId);
    if (list.contains(fp)) return;
    list.add(fp);
    await prefs.setString(_prefKey(rotaId), jsonEncode(list));
  }

  /// Mensagem quando o arquivo já entrou nesta rota.
  static const duplicateFileMessage =
      'Romaneio já importado nesta rota.\n\n'
      'Este arquivo (PDF ou planilha) já foi adicionado. '
      'Escolha outro romaneio ou crie uma rota nova do zero.';

  /// Quando o conteúdo bate com pacotes que já estão na lista (arquivo reexportado).
  static const duplicatePackagesMessage =
      'Romaneio já importado nesta rota.\n\n'
      'Todos os pacotes deste arquivo já estão na sua rota. '
      'Nada novo foi adicionado.';
}
