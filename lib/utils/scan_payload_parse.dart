import 'package:rota_prime/utils/spx_regex.dart';

/// Tenta extrair endereço legível do texto bruto do QR/código de barras.
String? extractAddressFromScanRaw(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;

  final cep = RegExp(r'\b(\d{5}-?\d{3})\b').firstMatch(t);
  final bairro = RegExp(r'Bairro[:\s]+([^,\|;\n]{3,80})', caseSensitive: false)
      .firstMatch(t);
  final rua = RegExp(
    r'(Rua|Av\.?|Avenida|Travessa|Alameda|Rodovia)[^,\|;\n]{5,120}',
    caseSensitive: false,
  ).firstMatch(t);

  final parts = <String>[];
  if (rua != null) parts.add(rua.group(0)!.trim());
  if (bairro != null) parts.add('Bairro ${bairro.group(1)!.trim()}');
  if (cep != null) parts.add('CEP ${cep.group(1)!}');

  if (parts.isEmpty) {
    if (t.contains('|')) {
      for (final seg in t.split('|')) {
        final s = seg.trim();
        if (s.length < 12) continue;
        if (looksLikeTrackingCode(s)) continue;
        if (RegExp(r'\d').hasMatch(s) &&
            RegExp(r'[A-Za-zÀ-ú]').hasMatch(s) &&
            !s.startsWith('http')) {
          return s;
        }
      }
    }
    return null;
  }
  return parts.join(', ');
}

/// Nome no texto do QR (etiquetas com vários campos).
String? extractNameFromScanRaw(String raw) {
  final t = raw.trim();
  if (t.length < 10) return null;
  final m = RegExp(
    r'([A-ZÀ-Ú][a-zà-ú]+(?:\s+[A-ZÀ-Ú][a-zà-ú]+){1,4})',
  ).firstMatch(t);
  if (m == null) return null;
  final name = m.group(1)!.trim();
  if (name.length < 6 || looksLikeTrackingCode(name)) return null;
  if (RegExp(r'\d{3,}').hasMatch(name)) return null;
  return name;
}

bool isTrackingOnlyText(String text) {
  final t = text.trim();
  if (t.isEmpty) return true;
  if (looksLikeTrackingCode(t)) return true;
  final code = extractTrackingCode(t);
  return code != null && code == t.toUpperCase();
}
