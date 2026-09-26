import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_core.dart';

/// Chave do local de entrega (mesmo AP / mesma casa = mesma chave).
String deliveryAddressKey(Parada p) {
  final core = buildAddressCoreKey(p);
  if (core.isNotEmpty) return core;

  var raw = normalizeAddressToken(addressTextForParada(p));
  if (raw.isNotEmpty) return raw;

  if (p.latitude != null && p.longitude != null) {
    final lat = p.latitude!.toStringAsFixed(5);
    final lng = p.longitude!.toStringAsFixed(5);
    return 'geo:$lat,$lng';
  }

  if (p.stop > 0) {
    final zip = p.zipcode.replaceAll(RegExp(r'\D'), '');
    final city = normalizeAddressToken(p.city);
    return 'stop:${p.stop}|$zip|$city';
  }

  return 'row:${p.id}_${p.ordemExibicao}';
}

bool sameDeliveryLocation(Parada a, Parada b) {
  if (deliveryAddressKey(a) == deliveryAddressKey(b)) return true;
  if (addressCoresSimilar(a, b)) return true;
  if (coordsWithinMeters(a, b, 28)) {
    final sa = extractStreetLine(normalizeAddressToken(addressTextForParada(a)));
    final sb = extractStreetLine(normalizeAddressToken(addressTextForParada(b)));
    final na = extractPrimaryStreetNumber(normalizeAddressToken(addressTextForParada(a)));
    final nb = extractPrimaryStreetNumber(normalizeAddressToken(addressTextForParada(b)));
    if (sa != null && sa == sb && na != null && na == nb) return true;
  }
  return false;
}

bool isBusinessDelivery(Parada p) {
  if (p.entregaComercial) return true;
  final t = '${p.destinationAddress} ${p.rawLine}'.toLowerCase();
  const hints = [
    ' ltda',
    ' eireli',
    ' s/a',
    ' s.a',
    ' cnpj',
    'loja ',
    'empresa',
    'comercial',
    ' mercado',
    ' padaria',
    ' restaurante',
    ' hotel',
    ' depósito',
    'deposito',
    ' consultório',
    'consultorio',
    ' clínica',
    'clinica',
    ' escola',
    ' igreja',
    ' lar de idosos',
    'bar ',
    'salão',
    'salao',
    ' oficina',
    ' posto ',
    ' farmácia',
    'farmacia',
  ];
  return hints.any(t.contains);
}
