import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';

class ImportDedupeOutcome {
  const ImportDedupeOutcome({
    required this.paradas,
    required this.duplicatesRemoved,
  });

  final List<Parada> paradas;
  final int duplicatesRemoved;
}

/// Remove linhas duplicadas do parse (PDF) — 1 ID = 1 pacote.
ImportDedupeOutcome dedupeImportParadas(List<Parada> input) {
  if (input.length < 2) {
    return ImportDedupeOutcome(
      paradas: List<Parada>.from(input),
      duplicatesRemoved: 0,
    );
  }

  final seen = <String>{};
  final out = <Parada>[];
  for (final p in input) {
    final ref = p.spxTn.trim();
    final key = ref.isNotEmpty
        ? 'ref:$ref'
        : 'seq:${p.sequence}|${p.zipcode}|${p.destinationAddress}'.toLowerCase();
    if (seen.add(key)) {
      out.add(p);
    }
  }
  final removed = input.length - out.length;
  if (removed == 0) {
    return ImportDedupeOutcome(
      paradas: List<Parada>.from(input),
      duplicatesRemoved: 0,
    );
  }

  for (var i = 0; i < out.length; i++) {
    final p = out[i];
    p.ordemExibicao = i + 1;
    if (p.romaneioLayout != ImportRomaneioLayout.shopeeOrdemPacote) {
      p.sequence = i + 1;
    }
  }
  return ImportDedupeOutcome(paradas: out, duplicatesRemoved: removed);
}

/// Chave estável para merge (ID do pacote ou endereço — ignora id Isar).
String mergeParadaDedupeKey(Parada p) {
  final ref = p.spxTn.trim();
  if (ref.isNotEmpty) return 'id:$ref';
  return 'addr:${deliveryAddressKey(p)}';
}

/// Quantos pacotes do arquivo ainda não existem na rota.
int countNewParadasForMerge(List<Parada> existing, List<Parada> incoming) {
  if (incoming.isEmpty) return 0;
  final seen = existing.map(mergeParadaDedupeKey).toSet();
  var added = 0;
  for (final p in incoming) {
    if (seen.add(mergeParadaDedupeKey(p))) added++;
  }
  return added;
}

/// Vários romaneios na mesma rota — só remove pacote já existente (mesmo ID).
List<Parada> mergeRouteParadas(List<Parada> existing, List<Parada> incoming) {
  final combined = [...existing, ...incoming];
  if (combined.length < 2) {
    for (var i = 0; i < combined.length; i++) {
      combined[i].ordemExibicao = i + 1;
    }
    return combined;
  }

  final seen = <String>{};
  final out = <Parada>[];
  for (final p in combined) {
    if (seen.add(mergeParadaDedupeKey(p))) {
      out.add(p);
    }
  }
  for (var i = 0; i < out.length; i++) {
    out[i].ordemExibicao = i + 1;
  }
  return out;
}
