import 'package:rota_prime/models/parada.dart';

/// Monta endereço para geocodificação e exibição (parada manual — plano grátis).
String buildManualFreeAddress({
  required String street,
  required String number,
  required String neighborhood,
  required String city,
  String? complement,
}) {
  final parts = [
    street.trim(),
    number.trim(),
    neighborhood.trim(),
    city.trim(),
  ].where((p) => p.isNotEmpty);
  var line = parts.join(', ');
  final comp = complement?.trim();
  if (comp != null && comp.isNotEmpty) {
    line = '$line — $comp';
  }
  return line;
}

/// Primeiro token da cidade (antes de UF), para filtrar geocodificação.
class ParsedManualAddress {
  const ParsedManualAddress({
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    this.complement,
  });

  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String? complement;
}

/// Preenche o formulário manual a partir de uma [Parada] salva.
ParsedManualAddress parseStoredParadaAddress(Parada parada) {
  var line = parada.destinationAddress.trim();
  String? complement;
  final dash = line.indexOf('—');
  if (dash >= 0) {
    complement = line.substring(dash + 1).trim();
    line = line.substring(0, dash).trim();
  }
  final parts = line
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  var street = parts.isNotEmpty ? parts.first : line;
  var number = '';
  var neighborhood = parada.bairro.trim();
  var city = parada.city.trim();

  if (parts.length >= 4) {
    street = parts[0];
    number = parts[1];
    neighborhood = neighborhood.isNotEmpty ? neighborhood : parts[2];
    city = city.isNotEmpty ? city : parts.sublist(3).join(', ');
  } else if (parts.length == 3) {
    street = parts[0];
    number = parts[1];
    neighborhood = neighborhood.isNotEmpty ? neighborhood : parts[2];
  } else if (parts.length == 2) {
    street = parts[0];
    number = parts[1];
  } else if (parts.length == 1) {
    street = parts[0];
  }

  return ParsedManualAddress(
    street: street,
    number: number,
    neighborhood: neighborhood,
    city: city,
    complement: complement?.isEmpty == true ? null : complement,
  );
}

String cityGeocodeToken(String cityField) {
  var s = cityField.trim();
  if (s.isEmpty) return '';
  final slash = s.split('/');
  s = slash.first.trim();
  final comma = s.split(',');
  s = comma.first.trim();
  return s.toLowerCase();
}
