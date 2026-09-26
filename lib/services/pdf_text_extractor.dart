import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

/// Extrai texto de PDF (romaneio) via Pdfium — mesmo motor do visualizador pdfrx.
Future<String> extractPdfPlainText(
  Uint8List bytes, {
  String? sourceName,
}) async {
  if (bytes.length < 5 ||
      bytes[0] != 0x25 ||
      bytes[1] != 0x50 ||
      bytes[2] != 0x44 ||
      bytes[3] != 0x46) {
    throw const FormatException('Arquivo não é um PDF válido');
  }

  final doc = await PdfDocument.openData(
    bytes,
    sourceName: sourceName ?? 'romaneio.pdf',
    useProgressiveLoading: false,
  );
  try {
    final buf = StringBuffer();
    for (final page in doc.pages) {
      final raw = await page.loadText();
      final t = raw?.fullText ?? '';
      if (t.isNotEmpty) {
        if (buf.isNotEmpty) buf.writeln();
        buf.write(t);
      }
    }
    final text = buf.toString().trim();
    if (text.isEmpty) {
      throw const FormatException(
        'PDF sem texto selecionável. Peça o romaneio em Excel (.xlsx) ou exporte o PDF com texto (não só imagem).',
      );
    }
    return text;
  } finally {
    await doc.dispose();
  }
}
