import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';

class HistoricoScreen extends ConsumerWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historicoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Histórico de rotas')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.white))),
        data: (rotas) {
          if (rotas.isEmpty) {
            return const Center(
              child: Text('Nenhuma rota finalizada ainda.', style: TextStyle(color: Colors.white70)),
            );
          }
          return ListView.builder(
            itemCount: rotas.length,
            itemBuilder: (context, i) {
              final r = rotas[i];
              final df = DateFormat('dd/MM/yyyy HH:mm');
              return ListTile(
                title: Text(r.titulo, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${r.paradasCount} paradas • ${df.format(r.finalizadaEm ?? r.criadaEm)}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () async {
                  await ref.read(rotaProvider.notifier).loadRota(r.id);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  navigateToRouteMap(context, ref);
                },
              );
            },
          );
        },
      ),
    );
  }
}
