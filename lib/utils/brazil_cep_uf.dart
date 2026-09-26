/// CEP → UF (faixas dos Correios, 2–3 primeiros dígitos).
library;

final _ufPattern = RegExp(
  r'\b(AC|AL|AP|AM|BA|CE|DF|ES|GO|MA|MT|MS|MG|PA|PB|PR|PE|PI|RJ|RN|RS|RO|RR|SC|SP|SE|TO)\b',
  caseSensitive: false,
);

/// Sigla UF a partir do CEP (8 dígitos).
String? ufFromBrazilCep(String cep) {
  final d = cep.replaceAll(RegExp(r'\D'), '');
  if (d.length < 2) return null;
  final p2 = int.parse(d.substring(0, 2));

  if (p2 >= 1 && p2 <= 19) return 'SP';
  if (p2 >= 20 && p2 <= 28) return 'RJ';
  if (p2 == 29) return 'ES';
  if (p2 >= 30 && p2 <= 39) return 'MG';
  if (p2 >= 40 && p2 <= 48) return 'BA';
  if (p2 == 49) return 'SE';
  if (p2 >= 50 && p2 <= 56) return 'PE';
  if (p2 == 57) return 'AL';
  if (p2 == 58) return 'PB';
  if (p2 == 59) return 'RN';
  if (p2 >= 60 && p2 <= 63) return 'CE';
  if (p2 == 64) return 'PI';
  if (p2 == 65) return 'MA';
  if (p2 == 66 || p2 == 67) return 'PA';
  if (p2 == 68) return 'AC';
  if (p2 == 69) {
    if (d.length >= 3) {
      final p3 = int.parse(d.substring(0, 3));
      if (p3 == 693) return 'RR';
      if (p3 == 699) return 'RO';
    }
    return 'AM';
  }
  if (p2 == 70 || p2 == 71 || p2 == 72) return 'DF';
  if (p2 >= 73 && p2 <= 76) return 'GO';
  if (p2 == 77) return 'TO';
  if (p2 == 78) return 'MT';
  if (p2 >= 79 && p2 <= 79) return 'MS';
  if (p2 >= 80 && p2 <= 87) return 'PR';
  if (p2 >= 88 && p2 <= 89) return 'SC';
  if (p2 >= 90 && p2 <= 99) return 'RS';
  return null;
}

/// Cidade genérica para hint de geocode quando o romaneio não traz nome.
String defaultCityLabelForUf(String uf) {
  switch (uf.toUpperCase()) {
    case 'AC':
      return 'Rio Branco';
    case 'AL':
      return 'Maceió';
    case 'AP':
      return 'Macapá';
    case 'AM':
      return 'Manaus';
    case 'BA':
      return 'Salvador';
    case 'CE':
      return 'Fortaleza';
    case 'DF':
      return 'Brasília';
    case 'ES':
      return 'Vitória';
    case 'GO':
      return 'Goiânia';
    case 'MA':
      return 'São Luís';
    case 'MT':
      return 'Cuiabá';
    case 'MS':
      return 'Campo Grande';
    case 'MG':
      return 'Belo Horizonte';
    case 'PA':
      return 'Belém';
    case 'PB':
      return 'João Pessoa';
    case 'PR':
      return 'Curitiba';
    case 'PE':
      return 'Recife';
    case 'PI':
      return 'Teresina';
    case 'RJ':
      return 'Rio de Janeiro';
    case 'RN':
      return 'Natal';
    case 'RS':
      return 'Porto Alegre';
    case 'RO':
      return 'Porto Velho';
    case 'RR':
      return 'Boa Vista';
    case 'SC':
      return 'Florianópolis';
    case 'SP':
      return 'São Paulo';
    case 'SE':
      return 'Aracaju';
    case 'TO':
      return 'Palmas';
    default:
      return '';
  }
}

/// Extrai UF de texto (endereço ou campo cidade "Curitiba/PR").
String? ufFromAddressText(String text) {
  final slash = RegExp(r'/([A-Z]{2})\b').firstMatch(text.toUpperCase());
  if (slash != null) return slash.group(1);
  final m = _ufPattern.firstMatch(text);
  return m?.group(1)?.toUpperCase();
}
