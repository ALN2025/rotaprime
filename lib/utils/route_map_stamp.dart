import 'package:rota_prime/models/parada.dart';

/// Carimbo leve para saber quando redesenhar pins (sem comparar a lista inteira).
int routeMapParadasStamp(List<Parada> paradas) {
  var h = paradas.length;
  if (paradas.isEmpty) return h;
  final take = paradas.length < 24 ? paradas.length : 24;
  for (var i = 0; i < take; i++) {
    final p = paradas[i];
    h = 0x1fffffff & (h + p.id * 31 + p.ordemExibicao * 17 + (p.entregue ? 1 : 0));
  }
  if (paradas.length > 24) {
    final p = paradas.last;
    h = 0x1fffffff & (h + p.id * 13 + p.ordemExibicao);
  }
  return h;
}
