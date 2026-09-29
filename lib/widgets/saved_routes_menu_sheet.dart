import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rota_prime/app/app_info.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/rota.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/providers/conta_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/screens/conta_rotas_screen.dart';
import 'package:rota_prime/widgets/spoke_widgets.dart';

Future<void> showSavedRoutesMenuSheet(
  BuildContext context,
  WidgetRef ref, {
  bool embeddedInShell = false,
  VoidCallback? onRouteOptions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.sheet,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, _) {
              final rotasAsync = ref.watch(contaRotasProvider);
              return SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SheetDragHandle(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppInfo.productName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            AppInfo.fullVersionLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rotas finalizadas e salvas',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: rotasAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.orange),
                        ),
                        error: (e, _) => Center(
                          child: Text('$e', style: const TextStyle(color: Colors.white54)),
                        ),
                        data: (rotas) {
                          final saved = rotas
                              .where(
                                (r) =>
                                    r.status == RotaStatus.finalizada ||
                                    r.status == RotaStatus.ativa,
                              )
                              .toList();
                          if (saved.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Nenhuma rota salva ainda.\nFinalize uma rota para aparecer aqui.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54, height: 1.4),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            itemCount: saved.length,
                            itemBuilder: (context, i) {
                              final r = saved[i];
                              return _SavedRouteTile(
                                rota: r,
                                onView: () async {
                                  Navigator.pop(ctx);
                                  await openSavedRouteFromList(
                                    context,
                                    ref,
                                    rotaId: r.id,
                                    embeddedInShell: embeddedInShell,
                                  );
                                },
                                onRedo: () async {
                                  Navigator.pop(ctx);
                                  if (!context.mounted) return;
                                  showDialog<void>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: Card(
                                        color: AppColors.sheet,
                                        child: Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(color: AppColors.orange),
                                              SizedBox(height: 16),
                                              Text(
                                                'Refazendo rota…',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                  try {
                                    await ref.read(rotaProvider.notifier).recreateRouteForTesting(
                                          r.id,
                                          reoptimize: true,
                                        );
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.of(context, rootNavigator: true).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('$e')),
                                      );
                                    }
                                    return;
                                  }
                                  if (context.mounted) {
                                    Navigator.of(context, rootNavigator: true).pop();
                                    navigateToRouteMap(context, ref);
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (onRouteOptions != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onRouteOptions();
                          },
                          icon: const Icon(Icons.tune),
                          label: const Text('Opções da rota atual'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

class _SavedRouteTile extends StatelessWidget {
  const _SavedRouteTile({
    required this.rota,
    required this.onView,
    required this.onRedo,
  });

  final RotaRecord rota;
  final VoidCallback onView;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    final refDate = rota.finalizadaEm ?? rota.criadaEm;
    final df = DateFormat('d \'de\' MMM', 'pt_BR');
    final status = switch (rota.status) {
      RotaStatus.finalizada => 'Finalizada',
      RotaStatus.ativa => 'Em andamento',
      RotaStatus.rascunho => 'Rascunho',
    };
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      df.format(refDate),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      rota.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$status · ${rota.paradasImportadas} paradas · ${rota.pacotesImportados} pacotes',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white38),
                color: AppColors.sheet,
                onSelected: (v) {
                  if (v == 'view') onView();
                  if (v == 'redo') onRedo();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('Ver rota', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'redo',
                    child: Text(
                      'Refazer e reotimizar (teste)',
                      style: TextStyle(color: AppColors.orange),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
