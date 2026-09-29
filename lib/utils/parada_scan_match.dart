import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/spx_regex.dart';

/// Encontra parada da rota pelo código lido no QR/código de barras.
Parada? findParadaForScanCode(List<Parada> paradas, String raw) {
  final code = (extractTrackingCode(raw) ??
          (looksLikeTrackingCode(raw) ? raw.trim().toUpperCase() : null))
      ?.trim();
  if (code == null || code.length < 4) return null;
  final c = code.toUpperCase();

  Parada? best;
  for (final p in paradas) {
    final spx = p.spxTn.trim().toUpperCase();
    if (spx.isEmpty) continue;
    if (spx == c || spx.contains(c) || c.contains(spx)) {
      return p;
    }
    final extracted = extractTrackingCode(spx);
    if (extracted != null && extracted == c) return p;
    if (best == null && spx.endsWith(c)) best = p;
  }
  return best;
}
