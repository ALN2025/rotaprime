import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/historico_item.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/utils/monthly_finance_report.dart';

class RelatorioMensalScreen extends ConsumerStatefulWidget {
  const RelatorioMensalScreen({super.key, required this.historico});

  final List<HistoricoItem> historico;

  @override
  ConsumerState<RelatorioMensalScreen> createState() => _RelatorioMensalScreenState();
}

class _RelatorioMensalScreenState extends ConsumerState<RelatorioMensalScreen> {
  late DateTime _month;
  MonthlyFinanceTotals? _totals;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rotas = historicoInMonth(widget.historico, _month.year, _month.month);
    final gastos = await ref.read(rotaProvider.notifier).loadGastosForRotaIds(
          rotas.map((r) => r.id),
        );
    if (!mounted) return;
    setState(() {
      _totals = buildMonthlyReport(
        year: _month.year,
        month: _month.month,
        rotasNoMes: rotas,
        gastosNoMes: gastos,
      );
      _loading = false;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Mês do relatório',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() => _month = DateTime(picked.year, picked.month));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final monthLabel = DateFormat('MMMM yyyy', 'pt_BR').format(_month);
    final t = _totals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Relatório mensal'),
        actions: [
          IconButton(
            tooltip: 'Copiar extrato',
            onPressed: t == null
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: financeReportPlainText(t, monthLabel)),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Relatório copiado')),
                    );
                  },
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OutlinedButton.icon(
                  onPressed: _pickMonth,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(monthLabel[0].toUpperCase() + monthLabel.substring(1)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 12),
                _explainCard(),
                const SizedBox(height: 16),
                if (t == null || t.routeCount == 0)
                  const Text(
                    'Nenhuma rota finalizada neste mês.',
                    style: TextStyle(color: Colors.white70),
                  )
                else ...[
                  Card(
                    color: t.lucro >= 0 ? AppColors.successGreen : Colors.red.shade800,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('Lucro líquido do mês', style: TextStyle(color: Colors.white70)),
                          Text(
                            currency.format(t.lucro),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Faturamento ${currency.format(t.faturamento)} − gastos ${currency.format(t.gastos)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _statRow('Rotas', '${t.routeCount}'),
                  _statRow('Entregas', '${t.entregues}'),
                  _statRow('KM rodado (odômetro)', t.kmRodado.toStringAsFixed(1)),
                  _statRow('Custo / KM', t.kmRodado > 0
                      ? currency.format(t.gastos / t.kmRodado)
                      : '—'),
                  _statRow('Lucro / KM', t.kmRodado > 0
                      ? currency.format(t.lucro / t.kmRodado)
                      : '—'),
                  if (t.gastosPorTipo.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Gastos reais por tipo',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: t.gastosPorTipo.entries.map((e) {
                            return PieChartSectionData(
                              value: e.value,
                              title: e.key,
                              color: _sliceColor(e.key),
                              radius: 56,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _explainCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Text(
        'O app não chuta km/l da moto ou carro. Você informa KM inicial e KM final '
        'do odômetro e lança os gastos reais (abastecimento, pedágio…). '
        'O gráfico soma o que foi registrado — serve para qualquer veículo.',
        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _sliceColor(String tipo) {
    return switch (tipo) {
      'Combustível' => AppColors.orange,
      'Pedágio' => Colors.blueAccent,
      'Alimentação' => Colors.teal,
      _ => Colors.blueGrey,
    };
  }
}
