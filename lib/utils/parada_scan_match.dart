import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/scan_payload_parse.dart';
import 'package:rota_prime/utils/spx_regex.dart';

String? normalizeScanCode(String raw) {
  return extractTrackingCode(raw) ??
      (looksLikeTrackingCode(raw) ? raw.trim().toUpperCase() : null);
}

bool paradaContainsScanCode(Parada p, String codeUpper) {
  final c = codeUpper.trim().toUpperCase();
  if (c.isEmpty) return false;

  final fields = [
    p.spxTn,
    p.rawLine,
    p.destinationAddress,
    p.packageOrderLabel,
  ];
  for (final raw in fields) {
    final f = raw.trim().toUpperCase();
    if (f.isEmpty) continue;
    if (f == c || f.contains(c)) return true;
    final extracted = extractTrackingCode(f);
    if (extracted != null && extracted == c) return true;
  }
  return false;
}

/// Endereço da parada se o texto não for só tracking.
String? realAddressFromParada(Parada p) {
  for (final candidate in [p.destinationAddress, p.rawLine]) {
    final t = candidate.trim();
    if (t.isEmpty) continue;
    if (isTrackingOnlyText(t)) continue;
    if (t.length >= 8 && RegExp(r'[A-Za-zÀ-ú]').hasMatch(t)) return t;
  }
  final loc = [p.bairro, p.city].where((s) => s.trim().isNotEmpty).join(' · ');
  if (loc.isNotEmpty) return loc;
  return null;
}

/// Encontra parada da rota pelo código lido no QR/código de barras.
Parada? findParadaForScanCode(List<Parada> paradas, String raw) {
  final code = normalizeScanCode(raw);
  if (code == null || code.length < 4) return null;
  final c = code.toUpperCase();

  for (final p in paradas) {
    if (paradaContainsScanCode(p, c)) return p;
  }
  return null;
}
