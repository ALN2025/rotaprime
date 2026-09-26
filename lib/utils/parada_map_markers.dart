import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';
import 'package:rota_prime/utils/parada_labels.dart';

/// Agrupa pins no mapa por coordenada ou endereço.
String mapPinGroupKey(Parada p) {
  if (p.latitude != null && p.longitude != null) {
    final lat = p.latitude!.toStringAsFixed(4);
    final lng = p.longitude!.toStringAsFixed(4);
    return 'geo:$lat,$lng';
  }
  return deliveryAddressKey(p);
}

bool sameMapPinGroup(Parada a, Parada b) {
  if (mapPinGroupKey(a) == mapPinGroupKey(b)) return true;
  return sameDeliveryLocation(a, b);
}

List<Parada> rowsInMapPinGroup(List<Parada> all, Parada anchor) {
  final key = mapPinGroupKey(anchor);
  return all.where((x) => mapPinGroupKey(x) == key).toList();
}

List<Parada> _rowsInMapPinGroup(List<Parada> all, Parada anchor) =>
    rowsInMapPinGroup(all, anchor);

List<Parada> representativeParadasForMap(
  List<Parada> all, {
  required bool hideCompleted,
}) {
  final withCoords = all.where((p) => p.latitude != null && p.longitude != null);
  final onePinPerPackage = ParadaLabels.routeUsesUnifiedPinOrder(all);

  if (onePinPerPackage) {
    final out = <Parada>[];
    for (final p in withCoords) {
      if (hideCompleted && (p.entregue || p.falha)) continue;
      out.add(p);
    }
    out.sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
    return out;
  }

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
  return map.values.toList();
}

/// Mesmo endereço GPS → desloca pins para ver cada pacote (Magalog/Loggi 1…N).
LatLng mapMarkerDisplayPoint(List<Parada> all, Parada p) {
  final lat = p.latitude!;
  final lng = p.longitude!;
  const eps = 0.00001;
  final peers = all
      .where((x) =>
          x.latitude != null &&
          x.longitude != null &&
          (x.latitude! - lat).abs() < eps &&
          (x.longitude! - lng).abs() < eps)
      .toList()
    ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
  if (peers.length <= 1) return LatLng(lat, lng);
  final i = peers.indexWhere((x) => x.id == p.id);
  final idx = i >= 0 ? i : 0;
  const radiusM = 22.0;
  final angle = (idx / peers.length) * 2 * math.pi;
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
