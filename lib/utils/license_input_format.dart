import 'dart:math';

/// Variantes do texto colado (espaços / blocos com traços decorativos).
List<String> licenseTokenCandidates(String raw) {
  final out = <String>[];
  void add(String s) {
    final t = s.trim();
    if (t.length > 20 && !out.contains(t)) out.add(t);
  }

  var block = raw.trim();
  if (block.isEmpty) return out;

  for (final line in block.split(RegExp(r'\r?\n'))) {
    final t = line.trim();
    if (t.contains('.') && t.length > 40) {
      add(t.replaceAll(RegExp(r'\s'), ''));
    }
  }

  add(block.replaceAll(RegExp(r'\s'), ''));

  // Licencas enviadas com tracos a cada 6 letras (WhatsApp) — 2ª tentativa.
  add(block.replaceAll(RegExp(r'[\s\-]'), ''));

  if (block.toUpperCase().startsWith('ROTA1')) {
    add(block.substring(5).replaceAll(RegExp(r'\s'), ''));
  }

  return out;
}

String normalizeLicenseInput(String raw) {
  final candidates = licenseTokenCandidates(raw);
  return candidates.isNotEmpty ? candidates.first : raw.trim().replaceAll(RegExp(r'\s'), '');
}

/// Chave única com traços (ex.: WhatsApp / banner) — o app remove os traços ao validar.
String formatLicenseDashed(String token, {int group = 4}) {
  final t = token.trim().replaceAll(RegExp(r'[\s\-]'), '');
  if (t.isEmpty) return t;
  final parts = <String>[];
  for (var i = 0; i < t.length; i += group) {
    parts.add(t.substring(i, min(i + group, t.length)));
  }
  return parts.join('-');
}

/// Agrupa com ESPAÇOS (legado).
String formatLicenseGrouped(String token, {int group = 8}) {
  final t = token.trim().replaceAll(RegExp(r'\s'), '');
  if (t.isEmpty) return t;
  final buf = StringBuffer();
  for (var i = 0; i < t.length; i += group) {
    if (i > 0) buf.write(' ');
    buf.write(t.substring(i, min(i + group, t.length)));
  }
  return buf.toString();
}

List<String> formatLicenseLines(String token, {int lineWidth = 36}) {
  final t = token.trim().replaceAll(RegExp(r'\s'), '');
  if (t.isEmpty) return [];
  final lines = <String>[];
  for (var i = 0; i < t.length; i += lineWidth) {
    lines.add(t.substring(i, min(i + lineWidth, t.length)));
  }
  return lines;
}

String licenseReferenceCode(String deviceId) {
  final d = deviceId.trim().toLowerCase();
  if (d.length <= 8) return d.toUpperCase();
  return d.substring(0, 8).toUpperCase();
}

/// Nome de arquivo seguro: `ANDERSON` ou `ANDERSON_735511F8` se já existir.
String licenseClientFileName(String buyerName, String deviceId, {bool fileAlreadyExists = false}) {
  var base = buyerName.trim().toUpperCase();
  base = base.replaceAll(RegExp(r'[^A-Z0-9\s\-_]'), '');
  base = base.replaceAll(RegExp(r'\s+'), '_');
  if (base.isEmpty) base = 'LICENCIADO';
  if (base.length > 48) base = base.substring(0, 48);
  if (fileAlreadyExists) {
    base = '${base}_${licenseReferenceCode(deviceId)}';
  }
  return '$base.txt';
}
