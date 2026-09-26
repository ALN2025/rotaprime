import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/gasto.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/screens/finalizar_rota_screen.dart';
import 'package:rota_prime/utils/route_finance_calc.dart';
import 'package:rota_prime/widgets/pro_gate.dart';

const gastoTipos = [
  'Combustível',
  'Pedágio',
  'Alimentação',
  'Estacionamento',
  'Manutenção',
  'Outros',
];

Future<void> openControleGastosPro(BuildContext context, WidgetRef ref) async {
  if (!await ensureProOrPrompt(context, ref, feature: 'Controle de gastos')) return;
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ControleGastosScreen()),
  );
}

class ControleGastosScreen extends ConsumerStatefulWidget {
  const ControleGastosScreen({super.key});

  @override
  ConsumerState<ControleGastosScreen> createState() => _ControleGastosScreenState();
}

class _ControleGastosScreenState extends ConsumerState<ControleGastosScreen> {
  final _kmInicialCtrl = TextEditingController();
  final _valorRotaCtrl = TextEditingController();
  final _kmFinalPreviewCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _kmInicialCtrl.dispose();
    _valorRotaCtrl.dispose();
    _kmFinalPreviewCtrl.dispose();
    super.dispose();
  }

  void _loadFromRota() {
    if (_loaded) return;
    final rota = ref.read(rotaProvider).rota;
    if (rota == null) return;
    _kmInicialCtrl.text = _formatNum(rota.kmInicial);
    _valorRotaCtrl.text = _formatNum(rota.valorPago);
    if (rota.kmFinal != null) {
      _kmFinalPreviewCtrl.text = _formatNum(rota.kmFinal!);
    }
    _loaded = true;
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }

  Future<void> _salvarBase() async {
    final km = parseMoneyOrKm(_kmInicialCtrl.text);
    final valor = parseMoneyOrKm(_valorRotaCtrl.text);
    await ref.read(rotaProvider.notifier).updateRouteFinanceBasics(
          kmInicial: km,
          valorPago: valor,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('KM inicial e valor da rota salvos')),
    );
  }

  Future<void> _addGasto() async {
    String tipo = gastoTipos.first;
    final valorCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              backgroundColor: AppColors.sheet,
              title: const Text('Novo gasto', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: gastoTipos
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => tipo = v);
                    },
                  ),
                  TextField(
                    controller: valorCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;
    final valor = parseMoneyOrKm(valorCtrl.text);
    if (valor <= 0) return;
    await ref.read(rotaProvider.notifier).addGasto(tipo, valor);
    if (mounted) setState(() {});
  }

  Future<void> _removeGasto(Gasto g) async {
    await ref.read(rotaProvider.notifier).removeGasto(g.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(subscriptionProvider).isPro;
    if (!isPro) {
      return Scaffold(
        appBar: AppBar(title: const Text('Controle de gastos')),
        body: const Center(
          child: Text('Recurso PRO', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    _loadFromRota();
    final state = ref.watch(rotaProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final gastoTotal = state.gastos.fold(0.0, (s, g) => s + g.valor);
    final kmPreview = _kmFinalPreviewCtrl.text.trim().isEmpty
        ? null
        : parseMoneyOrKm(_kmFinalPreviewCtrl.text);
    final summary = computeRouteFinance(
      kmInicial: parseMoneyOrKm(_kmInicialCtrl.text),
      kmFinal: kmPreview,
      valorRota: parseMoneyOrKm(_valorRotaCtrl.text),
      gastoTotal: gastoTotal,
      entregues: state.entregues,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Controle de gastos'),
        actions: [
          TextButton(
            onPressed: _salvarBase,
            child: const Text('Salvar', style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Lucro real = valor da rota − gastos que você lançou. '
            'KM rodado = odômetro final − inicial (não importa km/l da moto ou carro). '
            'Abastecimento entra como gasto em Combustível — o gráfico usa valores reais, '
            'não estimativa de consumo.',
            style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _field(
            controller: _kmInicialCtrl,
            label: 'KM inicial (odômetro)',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          _field(
            controller: _valorRotaCtrl,
            label: 'Valor da rota (R\$)',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          _field(
            controller: _kmFinalPreviewCtrl,
            label: 'KM final (opcional — prévia)',
            hint: 'Deixe vazio até terminar',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _SummaryCard(summary: summary, currency: currency),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Gastos da rota',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addGasto,
                icon: const Icon(Icons.add, color: AppColors.orange),
                label: const Text('Adicionar', style: TextStyle(color: AppColors.orange)),
              ),
            ],
          ),
          if (state.gastos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nenhum gasto ainda. Toque em Adicionar.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            ...state.gastos.map(
              (g) => Card(
                color: AppColors.card,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(g.tipo, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    DateFormat('dd/MM HH:mm').format(g.criadoEm),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currency.format(g.valor),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _removeGasto(g),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await _salvarBase();
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FinalizarRotaScreen()),
              );
            },
            style: primaryOrangeButtonStyle().copyWith(
              minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
            ),
            child: const Text('Finalizar rota e ver resultado'),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: AppColors.card,
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.currency});

  final RouteFinanceSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final lucroColor =
        summary.lucroLiquido >= 0 ? AppColors.successGreen : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            summary.kmFinal != null ? 'Resultado (com KM final)' : 'Prévia (sem KM final)',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(summary.lucroLiquido),
            style: TextStyle(
              color: lucroColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('Lucro líquido', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          _row('Faturamento', currency.format(summary.valorRota)),
          _row('Total gastos', currency.format(summary.gastoTotal)),
          if (summary.kmFinal != null) ...[
            _row('KM rodado', summary.kmRodado.toStringAsFixed(1)),
            _row('Lucro / KM', currency.format(summary.lucroPorKm)),
            _row('Custo / KM', currency.format(summary.custoPorKm)),
          ],
          if (summary.entregues > 0)
            _row('Lucro / entrega (${summary.entregues})', currency.format(summary.lucroPorEntrega)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
