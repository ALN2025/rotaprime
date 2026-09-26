import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/rota.dart';
import 'package:rota_prime/providers/conta_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/screens/configuracoes_screen.dart';
import 'package:rota_prime/screens/criar_rota_screen.dart';
import 'package:rota_prime/screens/rota_ativa_screen.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/widgets/add_parada_sheet.dart';
import 'package:rota_prime/widgets/continue_delivery_banner.dart';
import 'package:rota_prime/services/spreadsheet_picker.dart';

Future<void> openSavedRouteFromList(
  BuildContext context,
  WidgetRef ref, {
  required int rotaId,
  required bool embeddedInShell,
}) async {
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
              Text('Abrindo rota…', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    ),
  );
  Object? loadError;
  try {
    await ref.read(rotaProvider.notifier).loadRota(rotaId);
  } catch (e) {
    loadError = e;
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
  if (loadError != null) {
    if (!context.mounted) return;
    final msg = loadError is StateError ? loadError.message : loadError.toString();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        title: const Text('Não foi possível abrir', style: TextStyle(color: Colors.white)),
        content: Text(msg, style: const TextStyle(color: Colors.white70, height: 1.35)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    return;
  }
  if (!context.mounted) return;
  if (embeddedInShell) {
    navigateToRouteMap(context, ref);
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RotaAtivaScreen()),
    );
  }
}

class ContaRotasScreen extends ConsumerWidget {
  const ContaRotasScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rotasAsync = ref.watch(contaRotasProvider);
    final openRoute = ref.watch(rotaProvider);
    final hasOpenRoute =
        openRoute.rotaId != null && openRoute.paradas.isNotEmpty;

    final body = SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  if (!embeddedInShell)
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    )
                  else
                    const SizedBox(width: 8),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.sheet,
                          title: const Text('Ajuda', style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'Importe a planilha, otimize, entregue e finalize. '
                            'Rotas finalizadas ficam salvas por data nesta lista.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline, color: Colors.white70),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _LocalProfileHeader(),
            ),
            Expanded(
              child: rotasAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
                error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.white))),
                data: (rotas) {
                  RotaRecord? activeRoute;
                  for (final r in rotas) {
                    if (r.status == RotaStatus.ativa) {
                      activeRoute = r;
                      break;
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (activeRoute != null)
                        ContinueDeliveryBanner(
                          rota: activeRoute,
                          onContinue: () => openSavedRouteFromList(
                            context,
                            ref,
                            rotaId: activeRoute!.id,
                            embeddedInShell: embeddedInShell,
                          ),
                        ),
                      Expanded(
                        child: _RouteList(
                          rotas: rotas,
                          embeddedInShell: embeddedInShell,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                embeddedInShell ? 12 : MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await openManualParadaFlow(context, ref, prepareNewRoute: true);
                      if (ref.read(rotaProvider).paradas.isEmpty) return;
                      if (!context.mounted) return;
                      _openLoadedRoute(context, ref, active: false);
                    },
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Rota manual (sem planilha)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (hasOpenRoute) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(rotaProvider.notifier).loadRota(openRoute.rotaId!);
                        if (!context.mounted) return;
                        await pickSpreadsheetAndMergeIntoRoute(ref);
                      },
                      icon: const Icon(Icons.library_add_outlined),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      label: const Text(
                        'Adicionar romaneio à rota aberta',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => _openLoadedRoute(context, ref, active: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Continuar rota no mapa'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CriarRotaScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasOpenRoute ? AppColors.card : AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      hasOpenRoute
                          ? 'Nova rota (do zero)'
                          : '+ Criar rota (planilha ou manual)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

    if (embeddedInShell) {
      return ColoredBox(color: AppColors.background, child: body);
    }
    return Scaffold(backgroundColor: AppColors.background, body: body);
  }

  void _openLoadedRoute(BuildContext context, WidgetRef ref, {required bool active}) {
    if (embeddedInShell) {
      navigateToRouteMap(context, ref);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RotaAtivaScreen(),
      ),
    );
  }
}

class _LocalProfileHeader extends StatelessWidget {
  const _LocalProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.orange,
          child: const Text('RP', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ROTA PRIME',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Rotas salvas neste aparelho',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteList extends ConsumerWidget {
  const _RouteList({required this.rotas, required this.embeddedInShell});

  final List<RotaRecord> rotas;
  final bool embeddedInShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rotas.isEmpty) {
      return const Center(
        child: Text('Nenhuma rota ainda.', style: TextStyle(color: Colors.white54)),
      );
    }

    final sorted = List<RotaRecord>.from(rotas)
      ..sort((a, b) {
        if (a.status == RotaStatus.ativa && b.status != RotaStatus.ativa) return -1;
        if (b.status == RotaStatus.ativa && a.status != RotaStatus.ativa) return 1;
        return 0;
      });
    final groups = _groupRotas(sorted);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Text(
              g.label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
            ),
          ),
          for (final r in g.items)
            _RouteTile(
              rota: r,
              highlighted: g.label == 'Hoje' && g.items.first.id == r.id,
              onOpen: () => openSavedRouteFromList(
                context,
                ref,
                rotaId: r.id,
                embeddedInShell: embeddedInShell,
              ),
              onMenu: () => _routeMenu(context, ref, r),
            ),
        ],
      ],
    );
  }

  void _routeMenu(BuildContext context, WidgetRef ref, RotaRecord r) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sheet,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(r.titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Colors.white70),
              title: const Text('Abrir rota', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await openSavedRouteFromList(
                  context,
                  ref,
                  rotaId: r.id,
                  embeddedInShell: embeddedInShell,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(rotaProvider.notifier).deleteRotaById(r.id);
                ref.invalidate(contaRotasProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_RouteGroup> _groupRotas(List<RotaRecord> rotas) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final hoje = <RotaRecord>[];
    final mes = <RotaRecord>[];
    final older = <RotaRecord>[];

    for (final r in rotas) {
      final refDate = r.finalizadaEm ?? r.criadaEm;
      final d = DateTime(refDate.year, refDate.month, refDate.day);
      if (d == today) {
        hoje.add(r);
      } else if (!r.criadaEm.isBefore(monthStart)) {
        mes.add(r);
      } else {
        older.add(r);
      }
    }

    final out = <_RouteGroup>[];
    if (hoje.isNotEmpty) out.add(_RouteGroup('Hoje', hoje));
    if (mes.isNotEmpty) out.add(_RouteGroup('Início deste mês', mes));
    if (older.isNotEmpty) out.add(_RouteGroup('Anteriores', older));
    return out;
  }
}

class _RouteGroup {
  _RouteGroup(this.label, this.items);
  final String label;
  final List<RotaRecord> items;
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.rota,
    required this.highlighted,
    required this.onOpen,
    required this.onMenu,
  });

  final RotaRecord rota;
  final bool highlighted;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final refDate = rota.finalizadaEm ?? rota.criadaEm;
    final dfDate = DateFormat('d \'de\' MMM', 'pt_BR');
    final dfDay = DateFormat('EEEE', 'pt_BR');
    final statusLabel = switch (rota.status) {
      RotaStatus.finalizada => 'Finalizada',
      RotaStatus.ativa => 'Em andamento',
      RotaStatus.rascunho => 'Rascunho',
    };
    final emAndamento = rota.status == RotaStatus.ativa;
    return Material(
      color: emAndamento
          ? AppColors.orange.withValues(alpha: 0.14)
          : (highlighted ? AppColors.orange.withValues(alpha: 0.12) : Colors.transparent),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dfDate.format(refDate),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      dfDay.format(refDate),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rota.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: emAndamento ? AppColors.orange : AppColors.muted,
                        fontSize: 11,
                        fontWeight: emAndamento ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.more_vert, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
