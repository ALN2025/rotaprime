import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';
import 'package:rota_prime/utils/parada_labels.dart';

bool sameDeliveryStop(Parada a, Parada b) => sameDeliveryLocation(a, b);

List<Parada> pendingSiblingsAtSameStop(List<Parada> paradas, Parada after) {
  final siblings = paradas
      .where((p) =>
          p.id != after.id &&
          !p.entregue &&
          !p.falha &&
          sameDeliveryStop(p, after))
      .toList();
  siblings.sort(
    (a, b) => ParadaLabels.packageOrder(a).compareTo(ParadaLabels.packageOrder(b)),
  );
  return siblings;
}

/// Parada com entrega parcial: ainda falta pacote no mesmo endereço (prioridade máxima).
Parada? incompleteSameStopPendingPackage(List<Parada> paradas) {
  final seen = <String>{};
  for (final p in paradas) {
    final key = deliveryAddressKey(p);
    if (!seen.add(key)) continue;
    final group = paradas.where((x) => deliveryAddressKey(x) == key).toList();
    final hasFinished = group.any((x) => x.entregue || x.falha);
    final pending = group.where((x) => !x.entregue && !x.falha).toList();
    if (hasFinished && pending.isNotEmpty) {
      pending.sort(
        (a, b) => ParadaLabels.packageOrder(a).compareTo(ParadaLabels.packageOrder(b)),
      );
      return pending.first;
    }
  }
  return null;
}

/// Próximo alvo: outros pacotes na mesma parada (Stop), depois ordem da rota.
Parada? nextDeliveryTarget(List<Parada> paradas, Parada after) {
  final siblings = pendingSiblingsAtSameStop(paradas, after);
  if (siblings.isNotEmpty) return siblings.first;

  Parada? next;
  for (final p in paradas) {
    if (p.ordemExibicao <= after.ordemExibicao) continue;
    if (p.entregue || p.falha) continue;
    if (next == null || p.ordemExibicao < next.ordemExibicao) {
      next = p;
    }
  }
  return next;
}

/// Botão “Próxima”: pula para outra parada (não o próximo pacote no mesmo Stop).
Parada? skipToNextStopInRoute(List<Parada> paradas, Parada current) {
  Parada? candidate;
  for (final p in paradas) {
    if (p.ordemExibicao <= current.ordemExibicao) continue;
    if (p.entregue || p.falha) continue;
    if (sameDeliveryStop(p, current)) continue;
    if (candidate == null || p.ordemExibicao < candidate.ordemExibicao) {
      candidate = p;
    }
  }
  return candidate ?? nextDeliveryTarget(paradas, current);
}

/// Agrupa pacotes no **mesmo endereço** (não só o mesmo Stop da planilha).
List<Parada> clusterParadasByStopInRouteOrder(List<Parada> input) {
  if (input.isEmpty) return input;

  final sorted = List<Parada>.from(input)
    ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));

  final byAddress = <String, List<Parada>>{};
  for (final p in sorted) {
    byAddress.putIfAbsent(deliveryAddressKey(p), () => []).add(p);
  }
  for (final group in byAddress.values) {
    group.sort((a, b) =>
        ParadaLabels.packageOrder(a).compareTo(ParadaLabels.packageOrder(b)));
  }

  final indexOf = <Parada, int>{};
  for (var i = 0; i < sorted.length; i++) {
    indexOf[sorted[i]] = i;
  }

  final usedIndex = <int>{};
  final out = <Parada>[];

  for (var i = 0; i < sorted.length; i++) {
    if (usedIndex.contains(i)) continue;
    final p = sorted[i];
    final group = byAddress[deliveryAddressKey(p)]!;
    for (final s in group) {
      final idx = indexOf[s]!;
      if (usedIndex.add(idx)) out.add(s);
    }
  }

  for (var i = 0; i < out.length; i++) {
    out[i].ordemExibicao = i + 1;
  }
  return out;
}
