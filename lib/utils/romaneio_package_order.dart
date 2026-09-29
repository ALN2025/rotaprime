import 'package:rota_prime/utils/spx_regex.dart';

/// Ordem do pacote na planilha/PDF (ex.: Shopee `+2` = extra no romaneio, sem nº normal).
class RomaneioSheetOrder {
  const RomaneioSheetOrder({
    required this.sequence,
    this.displayLabel = '',
  });

  /// Valor numérico para ordenação interna.
  final int sequence;

  /// Texto exibido no chip (ex.: `+2`); vazio = usar sequence/tracking.
  final String displayLabel;
}

final _shopeePlusOrderPattern = RegExp(r'^\+\s*(\d+)\s*$');

/// `42`, `+2`, `+ 15` na coluna Sequence/Ordem/Pacote.
RomaneioSheetOrder parseRomaneioSheetOrder(String? raw, int displayOrder) {
  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty) {
    return RomaneioSheetOrder(sequence: displayOrder);
  }

  if (looksLikeTrackingCode(trimmed) && !_shopeePlusOrderPattern.hasMatch(trimmed)) {
    return RomaneioSheetOrder(sequence: displayOrder);
  }

  final plus = _shopeePlusOrderPattern.firstMatch(trimmed);
  if (plus != null) {
    final n = int.parse(plus.group(1)!);
    return RomaneioSheetOrder(sequence: n, displayLabel: '+${plus.group(1)!}');
  }

  final n = int.tryParse(trimmed) ?? 0;
  if (n > 0) {
    return RomaneioSheetOrder(sequence: n);
  }

  return RomaneioSheetOrder(sequence: displayOrder);
}

bool isShopeePlusOrderLabel(String label) {
  final t = label.trim();
  return t.isNotEmpty && _shopeePlusOrderPattern.hasMatch(t);
}

/// Campo manual “Ordem na sacola”: `47` ou `+2`.
({int? sequence, String displayLabel}) parseManualBagOrder(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return (sequence: null, displayLabel: '');
  }
  final plus = _shopeePlusOrderPattern.firstMatch(trimmed);
  if (plus != null) {
    final n = int.parse(plus.group(1)!);
    return (sequence: n, displayLabel: '+${plus.group(1)!}');
  }
  final n = int.tryParse(trimmed);
  if (n != null && n > 0) {
    return (sequence: n, displayLabel: '');
  }
  return (sequence: null, displayLabel: '');
}
