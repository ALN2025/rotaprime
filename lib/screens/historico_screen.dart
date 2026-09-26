import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/historico_item.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/screens/relatorio_mensal_screen.dart';
import 'package:rota_prime/utils/monthly_finance_report.dart';

class HistoricoScreen extends ConsumerStatefulWidget {
  const HistoricoScreen({super.key});

  @override
  ConsumerState<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends ConsumerState<HistoricoScreen> {
  DateTime? _filterDay;
  String _search = '';

  List<HistoricoItem> _filter(List<HistoricoItem> all) {
    var list = all;
    if (_filterDay != null) {
      list = historicoOnCalendarDay(list, _filterDay!);
    }
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) => r.titulo.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDay ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Dia da entrega',
    );
    if (picked == null) return;
    setState(() => _filterDay = DateTime(picked.year, picked.month, picked.day));
  }

  void _showExtrato(HistoricoItem r) {
    final df = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final text = StringBuffer()
      ..writeln(r.titulo)
      ..writeln('Dia: ${df.format(r.finalizadaEm ?? r.criadaEm)}')
      ..writeln('Paradas: ${r.paradasCount} · Entregues: ${r.entregues}')
      ..writeln('KM inicial: ${r.kmInicial.toStringAsFixed(1)}')
      ..writeln('KM final: ${r.kmFinal?.toStringAsFixed(1) ?? '—'}')
      ..writeln('KM rodado: ${r.kmRodado.toStringAsFixed(1)}')
      ..writeln('Valor rota: ${currency.format(r.valorPago)}')
      ..writeln('Gastos: ${currency.format(r.gastoTotal)}')
      ..writeln('Lucro: ${currency.format(r.lucroLiquido)}');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Extrato da rota',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              text.toString(),
              style: const TextStyle(color: Colors.white70, height: 1.45, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text.toString()));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Extrato copiado')),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar extrato'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historicoProvider);
    final df = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final dayFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Histórico de rotas'),
        actions: [
          IconButton(
            tooltip: 'Relatório mensal',
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () {
              history.whenData((items) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RelatorioMensalScreen(historico: items),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar rota…',
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos os dias'),
                  selected: _filterDay == null,
                  onSelected: (_) => setState(() => _filterDay = null),
                ),
                FilterChip(
                  label: Text(_filterDay == null ? 'Escolher dia' : dayFmt.format(_filterDay!)),
                  selected: _filterDay != null,
                  onSelected: (_) => _pickDay(),
                ),
                if (_filterDay != null)
                  ActionChip(
                    label: const Text('Limpar dia'),
                    onPressed: () => setState(() => _filterDay = null),
                  ),
              ],
            ),
          ),
          Expanded(
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
              error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.white))),
              data: (rotas) {
                final list = _filter(rotas);
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      _filterDay != null
                          ? 'Nenhuma rota neste dia.'
                          : 'Nenhuma rota finalizada ainda.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final r = list[i];
                    final lucro = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                        .format(r.lucroLiquido);
                    return ListTile(
                      title: Text(r.titulo, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${dayFmt.format(r.deliveryDay)} · ${r.paradasCount} paradas · '
                        'Lucro $lucro · ${df.format(r.finalizadaEm ?? r.criadaEm)}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                      onTap: () => _showExtrato(r),
                      onLongPress: () async {
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
          ),
        ],
      ),
    );
  }
}
