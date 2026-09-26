import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rota_prime/app/theme.dart';

typedef RouteOptionAction = Future<void> Function();

Future<void> showRouteOptionsSheet(
  BuildContext context, {
  required RouteOptionAction onReoptimize,
  required RouteOptionAction onDeleteRoute,
  required RouteOptionAction onFinishRoute,
  required RouteOptionAction onHistory,
  RouteOptionAction? onScanManifest,
  required RouteOptionAction onImportRomaneio,
  required bool routeHasRomaneioStops,
  required RouteOptionAction onCopyStops,
  required RouteOptionAction onRefreshGps,
  RouteOptionAction? onControleGastos,
  RouteOptionAction? onAddParadaManual,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.sheet,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _item(
                ctx,
                Icons.share_outlined,
                'Compartilhar resumo da rota',
                onCopyStops,
              ),
              _item(ctx, Icons.copy_all_outlined, 'Copiar paradas…', onCopyStops),
              _item(ctx, Icons.sync, 'Reotimizar rota…', onReoptimize),
              if (onAddParadaManual != null)
                _item(
                  ctx,
                  Icons.add_location_alt_outlined,
                  'Adicionar entrega manualmente…',
                  onAddParadaManual,
                ),
              if (onScanManifest != null)
                _item(ctx, Icons.qr_code_scanner, 'Ler manifesto (QR)', onScanManifest!),
              _item(
                ctx,
                routeHasRomaneioStops
                    ? Icons.library_add_outlined
                    : Icons.upload_file_outlined,
                routeHasRomaneioStops
                    ? 'Adicionar romaneio (PDF/planilha)…'
                    : 'Importar romaneio (PDF/planilha)…',
                onImportRomaneio,
              ),
              _item(ctx, Icons.gps_fixed, 'Atualizar GPS', onRefreshGps),
              if (onControleGastos != null)
                _item(ctx, Icons.account_balance_wallet_outlined, 'Controle de gastos (PRO)', onControleGastos),
              _item(ctx, Icons.history, 'Histórico de rotas', onHistory),
              _item(ctx, Icons.flag_outlined, 'Finalizar rota', onFinishRoute),
              _item(
                ctx,
                Icons.delete_outline,
                'Remover rota…',
                onDeleteRoute,
                destructive: true,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _item(
  BuildContext ctx,
  IconData icon,
  String label,
  RouteOptionAction action, {
  bool destructive = false,
}) {
  return ListTile(
    leading: Icon(icon, color: destructive ? Colors.red : Colors.white70),
    title: Text(
      label,
      style: TextStyle(
        color: destructive ? Colors.red : Colors.white,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: () async {
      Navigator.pop(ctx);
      await action();
    },
  );
}

Future<void> copyRouteSummaryToClipboard({
  required String title,
  required int stopCount,
  required List<String> lines,
}) async {
  final buffer = StringBuffer()
    ..writeln(title)
    ..writeln('$stopCount paradas')
    ..writeln()
    ..writeAll(lines, '\n');
  await Clipboard.setData(ClipboardData(text: buffer.toString()));
}
