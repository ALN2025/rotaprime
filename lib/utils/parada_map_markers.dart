import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';

/// Agrupa pins no mapa por endereço + AP/bloco (mesmo local = um pin).
String mapPinGroupKey(Parada p) => deliveryAddressKey(p);

bool sameMapPinGroup(Parada a, Parada b) =>
    mapPinGroupKey(a) == mapPinGroupKey(b);

List<Parada> rowsInMapPinGroup(List<Parada> all, Parada anchor) {
  final key = mapPinGroupKey(anchor);
  return all.where((x) => mapPinGroupKey(x) == key).toList();
}

List<Parada> _rowsInMapPinGroup(List<Parada> all, Parada anchor) =>
    rowsInMapPinGroup(all, anchor);

/// Um pin por endereço/unidade; vários pacotes no mesmo AP compartilham o pin.
List<Parada> representativeParadasForMap(
  List<Parada> all, {
  required bool hideCompleted,
}) {
  final withCoords = all.where((p) => p.latitude != null && p.longitude != null);
  final map = <String, Parada>{};
  for (final p in withCoords) {
    if (hideCompleted && (p.entregue || p.falha)) continue;
    final key = mapPinGroupKey(p);
    final existing = map[key];
    if (existing == null) {
      map[key] = p;
      continue;
    }
    final existingPending = !existing.entregue && !existing.falha;
    final pending = !p.entregue && !p.falha;
    if (pending && !existingPending) {
      map[key] = p;
    } else if (pending == existingPending &&
        p.ordemExibicao < existing.ordemExibicao) {
      map[key] = p;
    }
  }
  final out = map.values.toList()
    ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
  return out;
}

/// Vários APs no mesmo GPS (prédio) → pins em círculo, um por unidade.
LatLng mapMarkerDisplayPoint(List<Parada> all, Parada p) {
  final lat = p.latitude!;
  final lng = p.longitude!;
  const eps = 0.000018;
  final keyOrder = <String>[];
  for (final x in all) {
    if (x.latitude == null || x.longitude == null) continue;
    if ((x.latitude! - lat).abs() > eps || (x.longitude! - lng).abs() > eps) {
      continue;
    }
    final k = mapPinGroupKey(x);
    if (!keyOrder.contains(k)) keyOrder.add(k);
  }
  keyOrder.sort();
  if (keyOrder.length <= 1) return LatLng(lat, lng);
  final myKey = mapPinGroupKey(p);
  final idx = keyOrder.indexOf(myKey);
  if (idx < 0) return LatLng(lat, lng);
  const radiusM = 26.0;
  final angle = (idx / keyOrder.length) * 2 * math.pi;
  final dLat = radiusM * math.cos(angle) / 111320.0;
  final dLng = radiusM * math.sin(angle) / (111320.0 * math.cos(lat * math.pi / 180));
  return LatLng(lat + dLat, lng + dLng);
}

enum MapPinDeliveryState { pending, delivered, failed }

MapPinDeliveryState pinStateForAddress(List<Parada> all, Parada anchor) {
  final rows = _rowsInMapPinGroup(all, anchor);
  var anyPending = false;
  var anyFailed = false;
  var anyDelivered = false;
  for (final r in rows) {
    if (r.falha) {
      anyFailed = true;
    } else if (r.entregue) {
      anyDelivered = true;
    } else {
      anyPending = true;
    }
  }
  if (anyPending) return MapPinDeliveryState.pending;
  if (anyFailed) return MapPinDeliveryState.failed;
  if (anyDelivered) return MapPinDeliveryState.delivered;
  return MapPinDeliveryState.pending;
}

bool mapPinGroupIsFinished(List<Parada> all, Parada anchor) {
  final state = pinStateForAddress(all, anchor);
  return state == MapPinDeliveryState.delivered ||
      state == MapPinDeliveryState.failed;
}
