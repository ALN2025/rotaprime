final spxTrackingRegex = RegExp(
  r'\b(BR\d{10,14}[A-Z0-9]?|SPX\d+|ML\d+[A-Z]?|TBA\d+)\b',
  caseSensitive: false,
);

bool looksLikeTrackingCode(String value) {
  final t = value.trim();
  if (t.length < 6) return false;
  if (spxTrackingRegex.hasMatch(t)) return true;
  // QR genérico / romaneio: aceita alfanumérico longo
  return RegExp(r'^[A-Z0-9\-]{8,}$', caseSensitive: false).hasMatch(t);
}

String? extractTrackingCode(String value) {
  final match = spxTrackingRegex.firstMatch(value);
  return match?.group(0)?.toUpperCase();
}
