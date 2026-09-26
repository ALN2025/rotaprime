import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';

List<Parada> pendingParadasGroupedByAddress(List<Parada> pendingInRouteOrder) {
  final seen = <String>{};
  final out = <Parada>[];
  for (final p in pendingInRouteOrder) {
    if (seen.add(deliveryAddressKey(p))) out.add(p);
  }
  return out;
}

List<Parada> paradasAtSameAddress(List<Parada> all, Parada anchor) {
  final key = deliveryAddressKey(anchor);
  return all
      .where((p) => deliveryAddressKey(p) == key || sameDeliveryLocation(p, anchor))
      .toList();
}

List<Parada> pendingAtSameAddress(List<Parada> all, Parada anchor) {
  return paradasAtSameAddress(all, anchor)
      .where((p) => !p.entregue && !p.falha)
      .toList();
}
