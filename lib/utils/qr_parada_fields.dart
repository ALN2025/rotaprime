import 'package:rota_prime/models/parada.dart';

/// Metadados de parada incluída por QR (`rawLine` prefixo `QR;`).
class QrParadaFields {
  QrParadaFields._();

  static const prefix = 'QR;';

  static bool isQrParada(Parada p) => p.rawLine.trim().startsWith(prefix);

  static String format({
    required String code,
    String recipientName = '',
    String address = '',
  }) {
    final c = code.trim();
    final n = recipientName.trim();
    final a = address.trim();
    return '$prefix$c;$n;$a';
  }

  static ({String code, String recipientName, String address}) parse(Parada p) {
    final raw = p.rawLine.trim();
    if (!raw.startsWith(prefix)) {
      return (
        code: p.spxTn.trim(),
        recipientName: '',
        address: p.destinationAddress.trim(),
      );
    }
    final body = raw.substring(prefix.length);
    final parts = body.split(';');
    final code = parts.isNotEmpty ? parts[0].trim() : p.spxTn.trim();
    final name = parts.length > 1 ? parts[1].trim() : '';
    final addr = parts.length > 2 ? parts.sublist(2).join(';').trim() : '';
    return (
      code: code.isNotEmpty ? code : p.spxTn.trim(),
      recipientName: name,
      address: addr.isNotEmpty ? addr : p.destinationAddress.trim(),
    );
  }
}
