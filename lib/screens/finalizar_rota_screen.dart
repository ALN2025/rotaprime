import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/models/gasto.dart';
import 'package:rota_prime/providers/conta_provider.dart';

import 'package:rota_prime/providers/rota_provider.dart';

import 'package:rota_prime/providers/subscription_provider.dart';

import 'package:rota_prime/providers/app_shell_provider.dart';
import 'package:rota_prime/screens/app_shell_screen.dart';

import 'package:rota_prime/screens/controle_gastos_screen.dart';

import 'package:rota_prime/utils/route_finance_calc.dart';


class FinalizarRotaScreen extends ConsumerStatefulWidget {

  const FinalizarRotaScreen({super.key});



  @override

  ConsumerState<FinalizarRotaScreen> createState() => _FinalizarRotaScreenState();

}



class _FinalizarRotaScreenState extends ConsumerState<FinalizarRotaScreen> {

  final _kmFinalCtrl = TextEditingController();

  RouteFinanceSummary? _summary;

  bool _showResult = false;



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final rota = ref.read(rotaProvider).rota;

      if (rota?.kmFinal != null) {

        _kmFinalCtrl.text = rota!.kmFinal!.toStringAsFixed(1).replaceAll('.', ',');

      }

    });

  }



  @override

  void dispose() {

    _kmFinalCtrl.dispose();

    super.dispose();

  }



  Future<void> _finalizarGratis() async {

    await ref.read(rotaProvider.notifier).finalizeRoute(kmFinal: 0);

    ref.invalidate(contaRotasProvider);

    if (!mounted) return;

    ref.read(rotaProvider.notifier).clearWorkingRoute();

    switchAppShellTab(ref, 1);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShellScreen()),
      (r) => false,
    );

  }



  Future<void> _calcularPro() async {

    final state = ref.read(rotaProvider);

    final rota = state.rota;

    if (rota == null) return;



    final kmFinal = parseMoneyOrKm(_kmFinalCtrl.text);

    if (kmFinal <= 0) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Informe o KM final do odômetro')),

      );

      return;

    }

    if (kmFinal < rota.kmInicial) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('KM final não pode ser menor que o KM inicial')),

      );

      return;

    }



    final gastoTotal = state.gastos.fold(0.0, (s, g) => s + g.valor);

    _summary = computeRouteFinance(

      kmInicial: rota.kmInicial,

      kmFinal: kmFinal,

      valorRota: rota.valorPago,

      gastoTotal: gastoTotal,

      entregues: state.entregues,

    );



    await ref.read(rotaProvider.notifier).finalizeRoute(kmFinal: kmFinal);

    ref.invalidate(contaRotasProvider);

    setState(() => _showResult = true);

  }



  @override

  Widget build(BuildContext context) {

    final isPro = ref.watch(subscriptionProvider).isPro;

    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final state = ref.watch(rotaProvider);

    final rota = state.rota;



    if (!isPro) {

      return Scaffold(

        backgroundColor: AppColors.background,

        appBar: AppBar(title: const Text('Finalizar rota')),

        body: Padding(

          padding: const EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              const Text(

                'No plano Gratuito você encerra a rota sem o relatório financeiro.',

                style: TextStyle(color: Colors.white70, height: 1.4),

              ),

              const SizedBox(height: 16),

              OutlinedButton(

                onPressed: () => openControleGastosPro(context, ref),

                child: const Text('Ver controle de gastos (PRO)'),

              ),

              const Spacer(),

              ElevatedButton(

                onPressed: _finalizarGratis,

                style: primaryOrangeButtonStyle().copyWith(

                  minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),

                ),

                child: const Text('Concluir rota'),

              ),

            ],

          ),

        ),

      );

    }



    if (_showResult && _summary != null) {

      return _ResultView(

        summary: _summary!,

        currency: currency,

        gastos: state.gastos,

        valorRota: rota?.valorPago ?? 0,

        onDone: () {

          ref.read(rotaProvider.notifier).clearWorkingRoute();

          ref.invalidate(contaRotasProvider);

          switchAppShellTab(ref, 1);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AppShellScreen()),
            (r) => false,
          );

        },

      );

    }



    final gastoTotal = state.gastos.fold(0.0, (s, g) => s + g.valor);



    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(

        title: const Text('Finalizar rota'),

        actions: [

          IconButton(

            tooltip: 'Editar gastos',

            icon: const Icon(Icons.edit_note),

            onPressed: () => Navigator.of(context).push(

              MaterialPageRoute(builder: (_) => const ControleGastosScreen()),

            ),

          ),

        ],

      ),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          _infoTile('KM inicial', rota?.kmInicial.toStringAsFixed(1) ?? '—'),

          _infoTile('Valor da rota', currency.format(rota?.valorPago ?? 0)),

          _infoTile('Gastos registrados', currency.format(gastoTotal)),

          _infoTile('Entregas concluídas', '${state.entregues}'),

          const SizedBox(height: 16),

          TextField(

            controller: _kmFinalCtrl,

            keyboardType: const TextInputType.numberWithOptions(decimal: true),

            decoration: const InputDecoration(

              labelText: 'KM final (odômetro)',

              labelStyle: TextStyle(color: Colors.white70),

              helperText: 'KM rodado = final − inicial',

              helperStyle: TextStyle(color: AppColors.muted),

            ),

            style: const TextStyle(color: Colors.white),

          ),

          const SizedBox(height: 24),

          ElevatedButton(

            onPressed: _calcularPro,

            style: primaryOrangeButtonStyle().copyWith(

              minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),

            ),

            child: const Text('Calcular lucro real e finalizar'),

          ),

        ],

      ),

    );

  }



  Widget _infoTile(String label, String value) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 8),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [

          Text(label, style: const TextStyle(color: Colors.white54)),

          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),

        ],

      ),

    );

  }

}



class _ResultView extends StatelessWidget {

  const _ResultView({

    required this.summary,

    required this.currency,

    required this.gastos,

    required this.valorRota,

    required this.onDone,

  });



  final RouteFinanceSummary summary;

  final NumberFormat currency;

  final List<Gasto> gastos;

  final double valorRota;

  final VoidCallback onDone;



  @override

  Widget build(BuildContext context) {

    final gastosByTipo = <String, double>{};

    for (final g in gastos) {
      gastosByTipo[g.tipo] = (gastosByTipo[g.tipo] ?? 0) + g.valor;
    }



    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text('Resultado da rota')),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          Card(

            color: summary.lucroLiquido >= 0 ? AppColors.successGreen : Colors.red.shade800,

            child: Padding(

              padding: const EdgeInsets.all(24),

              child: Column(

                children: [

                  const Text('Lucro líquido real', style: TextStyle(color: Colors.white70)),

                  Text(

                    currency.format(summary.lucroLiquido),

                    style: const TextStyle(

                      color: Colors.white,

                      fontSize: 36,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  Text(

                    'Faturamento ${currency.format(valorRota)} − gastos ${currency.format(summary.gastoTotal)}',

                    style: const TextStyle(color: Colors.white70, fontSize: 12),

                    textAlign: TextAlign.center,

                  ),

                ],

              ),

            ),

          ),

          const SizedBox(height: 16),

          GridView.count(

            shrinkWrap: true,

            crossAxisCount: 2,

            crossAxisSpacing: 8,

            mainAxisSpacing: 8,

            physics: const NeverScrollableScrollPhysics(),

            children: [

              _gridTile('KM rodado', summary.kmRodado.toStringAsFixed(1)),

              _gridTile('Total gastos', currency.format(summary.gastoTotal)),

              _gridTile('Lucro / KM', currency.format(summary.lucroPorKm)),

              _gridTile('Custo / KM', currency.format(summary.custoPorKm)),

            ],

          ),

          if (summary.entregues > 0) ...[

            const SizedBox(height: 8),

            Text(

              'Lucro por entrega (${summary.entregues}): ${currency.format(summary.lucroPorEntrega)}',

              style: const TextStyle(color: Colors.white54),

            ),

          ],

          if (gastosByTipo.isNotEmpty) ...[

            const SizedBox(height: 16),

            SizedBox(

              height: 180,

              child: PieChart(

                PieChartData(

                  sections: gastosByTipo.entries.map((e) {

                    return PieChartSectionData(

                      value: e.value,

                      title: e.key,

                      color: AppColors.orange.withValues(alpha: 0.35 + (e.value % 3) * 0.15),

                      radius: 60,

                      titleStyle: const TextStyle(fontSize: 10, color: Colors.white),

                    );

                  }).toList(),

                ),

              ),

            ),

            for (final g in gastos)

              ListTile(

                title: Text(g.tipo, style: const TextStyle(color: Colors.white)),
                trailing: Text(currency.format(g.valor)),

              ),

          ],

          const SizedBox(height: 16),

          ElevatedButton(

            onPressed: onDone,

            style: primaryOrangeButtonStyle().copyWith(

              minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),

            ),

            child: const Text('Ver minhas rotas'),

          ),

        ],

      ),

    );

  }



  Widget _gridTile(String label, String value) {

    return Container(

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: const Color(0xFF1A1A1A),

        borderRadius: BorderRadius.circular(8),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),

          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

        ],

      ),

    );

  }

}


