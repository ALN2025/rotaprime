import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/parada_labels.dart';

/// Ordem do romaneio: sequência crescente (1, 2, 3…), não otimização por distância.
List<Parada> orderParadasByManifestSequence(List<Parada> input) {
  if (input.isEmpty) return input;

  final sorted = List<Parada>.from(input)
    ..sort((a, b) {
      final sa = ParadaLabels.packageOrder(a);
      final sb = ParadaLabels.packageOrder(b);
      final cmp = sa.compareTo(sb);
      if (cmp != 0) return cmp;
      if (a.stop != b.stop) return a.stop.compareTo(b.stop);
      return a.ordemExibicao.compareTo(b.ordemExibicao);
    });

  for (var i = 0; i < sorted.length; i++) {
    sorted[i].ordemExibicao = i + 1;
  }
  return sorted;
}

bool paradasMatchManifestOrder(List<Parada> paradas) {
  if (paradas.isEmpty) return true;
  final ordered = orderParadasByManifestSequence(paradas);
  for (var i = 0; i < paradas.length; i++) {
    if (paradas[i].id != ordered[i].id) return false;
  }
  return true;
}
