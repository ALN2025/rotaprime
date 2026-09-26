import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/screens/file_picker_screen.dart';
import 'package:rota_prime/services/spreadsheet_picker.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/widgets/add_parada_sheet.dart';
import 'package:rota_prime/app/app_navigator.dart';

/// Menu inferior: Ler documento / Importar arquivo / Pesquisar.
void showAddStopsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.sheet,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      final rotaSt = ref.read(rotaProvider);
      final hasRomaneioOnRoute =
          rotaSt.rotaId != null && rotaSt.paradas.isNotEmpty;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _AddStopTile(
                icon: hasRomaneioOnRoute
                    ? Icons.library_add_outlined
                    : Icons.table_chart_outlined,
                title: hasRomaneioOnRoute
                    ? 'Adicionar outro romaneio'
                    : 'Importar romaneio',
                subtitle: hasRomaneioOnRoute
                    ? 'PDF ou planilha na mesma rota'
                    : '1º arquivo — planilha ou PDF',
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (hasRomaneioOnRoute) {
                      await pickSpreadsheetAndMergeIntoRoute(ref);
                    } else {
                      rootNavigator?.push(
                        MaterialPageRoute(builder: (_) => const FilePickerScreen()),
                      );
                    }
                  });
                },
              ),
              const Divider(height: 1),
              _AddStopTile(
                icon: Icons.add_location_alt_outlined,
                title: 'Adicionar entrega manualmente',
                subtitle: 'Microfone ou digitar endereço',
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final navCtx = rootAppContext ?? sheetCtx;
                  await openManualParadaFlow(navCtx, ref, prepareNewRoute: true);
                  if (ref.read(rotaProvider).paradas.isEmpty) return;
                  final ctx = rootAppContext ?? navCtx;
                  if (ctx.mounted) navigateToRouteMap(ctx, ref);
                },
              ),
              const Divider(height: 1),
              _AddStopTile(
                icon: Icons.person_search_outlined,
                title: 'Pesquisar na rota',
                subtitle: 'Abrir mapa e buscar paradas',
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final nav = ref.read(rotaProvider.notifier);
                  if (ref.read(rotaProvider).rotaId == null) {
                    final loaded = await nav.loadLatestDraft();
                    if (!loaded) await nav.ensureEmptyDraftRota();
                  }
                  final ctx = rootAppContext ?? sheetCtx;
                  if (ctx.mounted) navigateToRouteMap(ctx, ref, openSearch: true);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AddStopTile extends StatelessWidget {
  const _AddStopTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white70, size: 26),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}
