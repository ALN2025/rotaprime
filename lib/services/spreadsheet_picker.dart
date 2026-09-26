import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/app_navigator.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/screens/mapeamento_colunas_screen.dart';

bool isSpreadsheetFile(PlatformFile file) {
  final name = file.name.toLowerCase();
  if (name.endsWith('.xlsx') ||
      name.endsWith('.xls') ||
      name.endsWith('.csv') ||
      name.endsWith('.pdf')) {
    return true;
  }
  final ext = file.extension?.toLowerCase();
  return ext == 'xlsx' || ext == 'xls' || ext == 'csv' || ext == 'pdf';
}

Future<Uint8List?> readPlatformFileBytes(PlatformFile file) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return file.bytes;
  }

  final stream = file.readStream;
  if (stream != null) {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    final data = builder.takeBytes();
    if (data.isNotEmpty) return data;
  }

  final path = file.path;
  if (path != null && path.isNotEmpty) {
    try {
      final data = await File(path).readAsBytes();
      if (data.isNotEmpty) return data;
    } catch (_) {}
  }

  return null;
}

void _snack(String message) {
  final ctx = rootAppContext;
  if (ctx == null) return;
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
  );
}

Future<void> _showImportError(String title, String message) async {
  final ctx = rootAppContext;
  if (ctx == null) {
    _snack('$title: $message');
    return;
  }
  await showDialog<void>(
    context: ctx,
    useRootNavigator: true,
    builder: (dctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(message, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('OK')),
      ],
    ),
  );
}

Future<void> _ensureRouteLoadedForMerge(WidgetRef ref) async {
  var st = ref.read(rotaProvider);
  if (st.rotaId != null && st.paradas.isNotEmpty) return;
  await ref.read(rotaProvider.notifier).loadLatestDraft();
}

/// Acrescenta romaneio à rota atual (Magalog + Loggi + Shopee…).
Future<void> pickSpreadsheetAndMergeIntoRoute(WidgetRef ref) async {
  await _ensureRouteLoadedForMerge(ref);
  final st = ref.read(rotaProvider);
  if (st.rotaId == null || st.paradas.isEmpty) {
    await _showImportError(
      'Rota não pronta',
      'Importe o 1º romaneio e aguarde terminar. Depois use '
          '“Adicionar outro romaneio” de novo — o arquivo será somado na mesma rota.',
    );
    return;
  }
  await _pickSpreadsheetImportCore(ref, merge: true);
}

/// Escolhe planilha e abre mapeamento → importação (nova rota).
Future<void> pickSpreadsheetAndImport(WidgetRef ref) async {
  await _pickSpreadsheetImportCore(ref, merge: false);
}

/// Se já existir rota com paradas, soma o arquivo; senão cria rota nova.
Future<void> pickRomaneioSmart(WidgetRef ref, {bool forceNewRoute = false}) async {
  final st = ref.read(rotaProvider);
  final merge =
      !forceNewRoute && st.rotaId != null && st.paradas.isNotEmpty;
  if (merge) {
    await _pickSpreadsheetImportCore(ref, merge: true);
  } else {
    await _pickSpreadsheetImportCore(ref, merge: false);
  }
}

Future<void> _pickSpreadsheetImportCore(WidgetRef ref, {required bool merge}) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf'],
      withData: true,
      withReadStream: true,
      allowMultiple: false,
      dialogTitle: 'Escolher romaneio (planilha ou PDF)',
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.first;
    _snack('Lendo ${picked.name}…');

    var bytes = await readPlatformFileBytes(picked);
    if (bytes == null || bytes.isEmpty) {
      bytes = picked.bytes;
    }

    if (bytes == null || bytes.isEmpty) {
      await _showImportError(
        'Não foi possível ler o arquivo',
        'Salve o romaneio em Downloads (.xlsx, .csv ou PDF com texto).\n'
            'Depois: Importar → menu ⋮ → Downloads → seu arquivo.',
      );
      return;
    }

    final name = picked.name.isNotEmpty ? picked.name : 'romaneio.xlsx';
    try {
      final nav = ref.read(rotaProvider.notifier);
      if (merge) {
        await nav.prepareMergeImportFromBytes(bytes, fileName: name);
      } else {
        await nav.prepareNewImportFromBytes(bytes, fileName: name);
      }
    } on FormatException catch (e) {
      await _showImportError('Planilha inválida', e.message);
      return;
    } on StateError catch (e) {
      await _showImportError('Importação', e.message);
      return;
    }

    final nav = rootNavigator;
    if (nav == null || !nav.mounted) {
      _snack('Erro de navegação. Feche e abra o app de novo.');
      return;
    }

    await nav.push(
      MaterialPageRoute(
        builder: (_) => MapeamentoColunasScreen(addingToExistingRoute: merge),
      ),
    );
  } catch (e) {
    await _showImportError('Erro ao importar', e.toString());
  }
}
