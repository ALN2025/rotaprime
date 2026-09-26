import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';

const _distance = Distance();

/// Parada pendente mais próxima de [from] (entregas já feitas são ignoradas).
Parada? nearestPendingParada(List<Parada> paradas, LatLng from) {
  Parada? best;
  var bestMeters = double.infinity;
  for (final p in paradas) {
    if (p.entregue || p.falha) continue;
    final lat = p.latitude;
    final lng = p.longitude;
    if (lat == null || lng == null) continue;
    final m = _distance.as(LengthUnit.Meter, from, LatLng(lat, lng));
    if (m < bestMeters) {
      bestMeters = m;
      best = p;
    }
  }
  return best;
}

LatLng? latLngForParada(Parada p) {
  if (p.latitude == null || p.longitude == null) return null;
  return LatLng(p.latitude!, p.longitude!);
}

/// Ordena pendentes pela distância até [from] (mais perto primeiro).
List<Parada> pendingParadasByDistance(List<Parada> paradas, LatLng? from) {
  final pending = paradas.where((p) => !p.entregue && !p.falha).toList();
  if (from == null) {
    pending.sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
    return pending;
  }
  pending.sort((a, b) {
    final la = latLngForParada(a);
    final lb = latLngForParada(b);
    if (la == null && lb == null) return a.ordemExibicao.compareTo(b.ordemExibicao);
    if (la == null) return 1;
    if (lb == null) return -1;
    final da = _distance.as(LengthUnit.Meter, from, la);
    final db = _distance.as(LengthUnit.Meter, from, lb);
    final cmp = da.compareTo(db);
    if (cmp != 0) return cmp;
    return a.ordemExibicao.compareTo(b.ordemExibicao);
  });
  return pending;
}
