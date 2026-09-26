import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_core.dart'
    show
        addressTextForParada,
        buildAddressCoreKey,
        canonicalStreetLine,
        coordsWithinMeters,
        extractDeliveryUnitSegment,
        extractPrimaryStreetNumber,
        extractStreetLine,
        normalizeAddressToken;

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

/// Mesmo local de entrega: **mesmo logradouro + mesmo número** (não só a rua).
bool sameDeliveryLocation(Parada a, Parada b) {
  final ca = buildAddressCoreKey(a);
  final cb = buildAddressCoreKey(b);
  if (ca.isNotEmpty && cb.isNotEmpty) return ca == cb;
  if (deliveryAddressKey(a) == deliveryAddressKey(b)) return true;

  final ta = normalizeAddressToken(addressTextForParada(a));
  final tb = normalizeAddressToken(addressTextForParada(b));
  final ua = extractDeliveryUnitSegment(ta);
  final ub = extractDeliveryUnitSegment(tb);
  if (ua.isNotEmpty && ub.isNotEmpty && ua != ub) return false;
  if (ua.isNotEmpty || ub.isNotEmpty) {
    return ua == ub && buildAddressCoreKey(a) == buildAddressCoreKey(b);
  }

  final na = extractPrimaryStreetNumber(ta);
  final nb = extractPrimaryStreetNumber(tb);
  if (na == null || nb == null || na != nb) return false;

  final sa = canonicalStreetLine(extractStreetLine(ta));
  final sb = canonicalStreetLine(extractStreetLine(tb));
  if (sa.isEmpty || sb.isEmpty || sa != sb) return false;

  return coordsWithinMeters(a, b, 12);
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
