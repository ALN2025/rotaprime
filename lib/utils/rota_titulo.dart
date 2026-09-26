import 'package:intl/intl.dart';

const _weekdayNames = [
  'segunda-feira',
  'terça-feira',
  'terca-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'sabado',
  'domingo',
];

bool isGenericRouteLabel(String? label) {
  if (label == null || label.trim().isEmpty) return true;
  final n = label.trim().toLowerCase();
  if (_weekdayNames.contains(n)) return true;
  if (n == 'rota' || n == 'nova rota') return true;
  return false;
}

String _suffixFromImportFileName(String? fileName) {
  if (fileName == null || fileName.trim().isEmpty) return 'ROTA PRIME';
  var base = fileName.trim();
  final lower = base.toLowerCase();
  if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
    base = base.substring(0, base.lastIndexOf('.'));
  }
  return _stripLeadingDateFromLabel(base.replaceAll('_', ' ').trim().toUpperCase());
}

/// Remove data já presente no nome do arquivo (evita `22-09-2026 22-09-2026 …`).
final _leadingDatePattern = RegExp(
  r'^(\d{2}[-/]\d{2}[-/]\d{4}|\d{2}/\d{2}/\d{4})\s*',
);

String _stripLeadingDateFromLabel(String text) {
  var t = text.trim();
  while (_leadingDatePattern.hasMatch(t)) {
    t = t.replaceFirst(_leadingDatePattern, '').trim();
  }
  return t.isEmpty ? 'ROTA PRIME' : t;
}

bool _tituloAlreadyHasDate(String titulo, DateTime when) {
  final t = titulo.trim();
  if (t.isEmpty) return false;
  final dfDash = DateFormat('dd-MM-yyyy').format(when);
  final dfSlash = DateFormat('dd/MM/yyyy', 'pt_BR').format(when);
  return t.startsWith(dfDash) ||
      t.startsWith(dfSlash) ||
      t.contains(' · ${DateFormat('HH:mm').format(when)}');
}

/// Título: `22/09/2026 · ANDERSON LUIS · 14:32` (pt-BR).
String buildRotaTitulo({
  required DateTime when,
  String? nomeOpcional,
  String? importFileName,
}) {
  final datePart = DateFormat('dd/MM/yyyy', 'pt_BR').format(when);
  final timePart = DateFormat('HH:mm', 'pt_BR').format(when);

  String suffix;
  if (!isGenericRouteLabel(nomeOpcional)) {
    suffix = _stripLeadingDateFromLabel(nomeOpcional!.trim().toUpperCase());
  } else {
    suffix = _suffixFromImportFileName(importFileName);
  }

  return '$datePart · $suffix · $timePart';
}

String tituloFromImportFileName(String? fileName) {
  return buildRotaTitulo(
    when: DateTime.now(),
    importFileName: fileName,
  );
}

String ensureTituloComData(String titulo, DateTime when) {
  final t = titulo.trim();
  if (t.isEmpty) return buildRotaTitulo(when: when);
  if (_tituloAlreadyHasDate(t, when)) {
    return t;
  }
  return buildRotaTitulo(when: when, nomeOpcional: _stripLeadingDateFromLabel(t));
}

String defaultWeekdayRouteLabel(DateTime when) {
  const weekdays = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];
  return weekdays[when.weekday - 1];
}
