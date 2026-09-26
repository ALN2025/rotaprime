import 'package:latlong2/latlong.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/brazil_cep_uf.dart';

const _distance = Distance();

String stripDiacritics(String input) {
  const from = 'àáâãäåæçèéêëìíîïñòóôõöøùúûüýÿ';
  const to = 'aaaaaaaceeeeiiiinooooooouuuuyy';
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (var i = 0; i < lower.length; i++) {
    final c = lower[i];
    final idx = from.indexOf(c);
    buf.write(idx >= 0 ? to[idx] : c);
  }
  return buf.toString();
}

String normalizeAddressToken(String input) {
  var s = stripDiacritics(input.trim().toLowerCase());
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(RegExp(r'[.;|]+'), ',');
  s = s.replaceAll(RegExp(r',\s*,+'), ',');
  s = s.replaceAll(RegExp(r'[,\s]+$'), '');
  s = s.replaceAll('nº', 'n');
  s = s.replaceAll('n°', 'n');
  s = s.replaceAll(RegExp(r'\bn\.?\s*'), 'n ');
  s = s.replaceAll(RegExp(r'\bnumero\b'), 'n');
  s = s.replaceAll(RegExp(r'\bnum\b'), 'n');
  s = s.replaceAll(RegExp(r'\bapto\.?\b'), 'ap ');
  s = s.replaceAll(RegExp(r'\bapartamento\b'), 'ap ');
  return s.trim();
}

/// Remove nome do destinatário no início (planilha Shopee).
String stripRecipientNamePrefix(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return s;

  final parts = s.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  if (parts.length < 2) return s;

  final first = parts.first.toLowerCase();
  final restJoined = parts.sublist(1).join(', ').toLowerCase();
  const streetHints = [
    'rua ',
    'r ',
    'avenida ',
    'av ',
    'travessa ',
    'tv ',
    'estrada ',
    'rodovia ',
    'alameda ',
    'praca ',
    'largo ',
    'cond ',
    'residencial ',
    'edificio ',
    'ed ',
  ];
  final looksLikeStreet =
      streetHints.any(restJoined.contains) || RegExp(r'\d').hasMatch(restJoined);
  final firstLooksLikeName = !RegExp(r'\d').hasMatch(first) &&
      first.length <= 48 &&
      !streetHints.any(first.startsWith);

  if (looksLikeStreet && firstLooksLikeName) {
    return parts.sublist(1).join(', ');
  }
  return s;
}

String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

String? extractPrimaryStreetNumber(String normalizedAddress) {
  final s = normalizedAddress;
  if (s.isEmpty) return null;

  final afterComma = RegExp(r',\s*n?\s*(\d{1,6})\b').firstMatch(s);
  if (afterComma != null) return afterComma.group(1);

  final inline = RegExp(r'\bn\s+(\d{1,6})\b').firstMatch(s);
  if (inline != null) return inline.group(1);

  final trailing = RegExp(r'\b(\d{1,6})\s*(?:,|$)').allMatches(s).toList();
  if (trailing.isNotEmpty) return trailing.last.group(1);
  return null;
}

String? extractStreetLine(String normalizedAddress) {
  final s = normalizedAddress;
  if (s.isEmpty) return null;
  const prefixes = [
    'rua ',
    'r ',
    'avenida ',
    'av ',
    'travessa ',
    'tv ',
    'estrada ',
    'rodovia ',
    'alameda ',
    'praca ',
    'largo ',
    'cond ',
    'residencial ',
  ];
  for (final prefix in prefixes) {
    final idx = s.indexOf(prefix);
    if (idx >= 0) {
      final slice = s.substring(idx).split(',').first.trim();
      if (slice.length >= 4) return slice;
    }
  }
  final first = s.split(',').first.trim();
  if (first.length >= 4 && RegExp(r'[a-z]').hasMatch(first)) return first;
  return null;
}

String addressTextForParada(Parada p) {
  var text = p.destinationAddress.trim();
  if (text.isEmpty) text = p.rawLine.trim();
  return stripRecipientNamePrefix(text);
}

/// Chave estável: logradouro + número + CEP + cidade (complemento e nome não separam).
String buildAddressCoreKey(Parada p) {
  final text = normalizeAddressToken(addressTextForParada(p));
  final street = extractStreetLine(text);
  final number = extractPrimaryStreetNumber(text);
  final zip = _digitsOnly(p.zipcode);
  final city = normalizeAddressToken(p.city);
  final bairro = normalizeAddressToken(p.bairro);

  if (street != null && number != null) {
    final parts = <String>[street, 'n$number'];
    if (zip.length >= 8) parts.add('cep$zip');
    if (city.isNotEmpty) {
      parts.add(city);
    } else if (bairro.isNotEmpty) {
      parts.add(bairro);
    }
    return parts.join('|');
  }

  if (text.isNotEmpty) {
    final compact = text.split(',').take(2).join(',').trim();
    if (zip.length >= 8) return '$compact|cep$zip';
    if (city.isNotEmpty) return '$compact|$city';
    return compact;
  }
  return '';
}

/// Cidade + UF para busca no mapa — Brasil inteiro (CEP, campo cidade, endereço).
({String city, String uf}) paradaCityAndUf(Parada p) {
  var raw = p.city.trim();
  final slash = raw.lastIndexOf('/');
  if (slash > 0 && slash < raw.length - 1) {
    final uf = raw.substring(slash + 1).trim().toUpperCase();
    if (RegExp(r'^[A-Z]{2}$').hasMatch(uf)) {
      return (
        city: raw.substring(0, slash).trim(),
        uf: uf,
      );
    }
  }

  final zip = _digitsOnly(p.zipcode);
  final ufFromZip = ufFromBrazilCep(zip);
  final addrText = addressTextForParada(p);
  final ufFromAddr = ufFromAddressText(addrText);
  final uf = ufFromZip ?? ufFromAddr ?? '';

  if (raw.isNotEmpty) {
    return (city: raw, uf: uf);
  }

  if (uf.isNotEmpty) {
    return (city: defaultCityLabelForUf(uf), uf: uf);
  }

  return (city: '', uf: '');
}

/// Texto limpo para buscar no mapa (porta do prédio / número na rua).
String geocodeQueryForParada(Parada p) {
  final raw = addressTextForParada(p);
  final norm = normalizeAddressToken(raw);
  final street = extractStreetLine(norm);
  final number = extractPrimaryStreetNumber(norm);
  final loc = paradaCityAndUf(p);
  final bairro = p.bairro.trim();
  final zip = p.zipcode.trim();

  if (street != null && number != null) {
    final parts = <String>[street, number];
    if (bairro.isNotEmpty) parts.add(bairro);
    if (loc.city.isNotEmpty) parts.add(loc.city);
    if (zip.isNotEmpty) parts.add(zip);
    if (loc.uf.isNotEmpty) parts.add(loc.uf);
    parts.add('Brasil');
    return parts.join(', ');
  }

  if (raw.isNotEmpty) {
    final locPart = <String>[
      if (loc.city.isNotEmpty) loc.city,
      if (loc.uf.isNotEmpty) loc.uf,
    ].join(', ');
    if (locPart.isNotEmpty) return '$raw, $locPart, Brasil';
    if (zip.isNotEmpty) return '$raw, $zip, Brasil';
    return '$raw, Brasil';
  }

  if (zip.length >= 8) return '$zip, Brasil';
  return '';
}

bool coordsWithinMeters(Parada a, Parada b, double meters) {
  if (a.latitude == null ||
      a.longitude == null ||
      b.latitude == null ||
      b.longitude == null) {
    return false;
  }
  final d = _distance.as(
    LengthUnit.Meter,
    LatLng(a.latitude!, a.longitude!),
    LatLng(b.latitude!, b.longitude!),
  );
  return d <= meters;
}

bool addressCoresSimilar(Parada a, Parada b) {
  final ca = buildAddressCoreKey(a);
  final cb = buildAddressCoreKey(b);
  if (ca.isNotEmpty && ca == cb) return true;

  if (a.stop > 0 && a.stop == b.stop) {
    final cityA = normalizeAddressToken(a.city);
    final cityB = normalizeAddressToken(b.city);
    final zipA = _digitsOnly(a.zipcode);
    final zipB = _digitsOnly(b.zipcode);
    if (cityA.isNotEmpty &&
        cityA == cityB &&
        zipA.length >= 8 &&
        zipA == zipB) {
      return true;
    }
  }
  return false;
}
