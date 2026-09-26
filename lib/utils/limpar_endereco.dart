import 'package:rota_prime/utils/brazil_cep_uf.dart';

bool addressHasLocationContext(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return false;
  if (RegExp(r'\b\d{5}-?\d{3}\b').hasMatch(s)) return true;
  if (ufFromAddressText(s) != null) return true;
  if (s.toLowerCase().contains('brasil')) return true;
  final parts = s.split(',').where((p) => p.trim().isNotEmpty).length;
  return parts >= 3;
}

String limparEndereco(String raw, {String defaultCity = ''}) {
  var s = raw.trim();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(RegExp(r'[;|]+'), ', ');
  s = s.replaceAll(RegExp(r',\s*,+'), ', ');
  s = s.replaceAll(RegExp(r'\b(entregar somente.*)$', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'\(.*?\)'), '');
  if (!addressHasLocationContext(s)) {
    final city = defaultCity.trim();
    if (city.isNotEmpty && !s.toLowerCase().contains(city.toLowerCase())) {
      if (city.contains('/')) {
        s = '$s, $city, Brasil';
      } else {
        final cepIn = RegExp(r'\b(\d{8})\b').firstMatch(s);
        final uf = cepIn != null ? ufFromBrazilCep(cepIn.group(1)!) : null;
        if (uf != null && uf.isNotEmpty) {
          s = '$s, $city, $uf, Brasil';
        } else {
          s = '$s, $city, Brasil';
        }
      }
    }
  } else if (!s.toLowerCase().contains('brasil')) {
    s = '$s, Brasil';
  }
  return s.trim().replaceAll(RegExp(r',\s*$'), '');
}

/// Cidade para [Parada.city] a partir do texto digitado (manual).
String inferCityFromAddress(String address, {String fallback = ''}) {
  var line = address.split('—').first.trim();
  line = line.replaceAll(RegExp(r'\bBrasil\b', caseSensitive: false), '').trim();
  final parts = line
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return fallback;

  String stripUf(String part) {
    final slash = RegExp(r'^(.+?)\s*/\s*([A-Z]{2})$').firstMatch(part);
    if (slash != null) return slash.group(1)!.trim();
    final tokens = part.split(RegExp(r'\s+'));
    if (tokens.length >= 2 && ufFromAddressText(tokens.last) != null) {
      return tokens.sublist(0, tokens.length - 1).join(' ');
    }
    return part;
  }

  for (var i = parts.length - 1; i >= 0; i--) {
    final p = stripUf(parts[i]);
    if (p.length < 2) continue;
    if (RegExp(r'^\d+$').hasMatch(p)) continue;
    if (RegExp(r'^\d{5}-?\d{3}$').hasMatch(p.replaceAll(' ', ''))) continue;
    if (ufFromAddressText(p) != null) continue;
    if (p.toLowerCase() == 'brasil') continue;
    return p;
  }
  return fallback;
}
