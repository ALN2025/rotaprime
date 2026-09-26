import 'package:rota_prime/models/gasto.dart';
import 'package:rota_prime/models/historico_item.dart';

class MonthlyFinanceTotals {
  const MonthlyFinanceTotals({
    required this.year,
    required this.month,
    required this.routeCount,
    required this.faturamento,
    required this.gastos,
    required this.lucro,
    required this.kmRodado,
    required this.entregues,
    required this.gastosPorTipo,
  });

  final int year;
  final int month;
  final int routeCount;
  final double faturamento;
  final double gastos;
  final double lucro;
  final double kmRodado;
  final int entregues;
  final Map<String, double> gastosPorTipo;
}

MonthlyFinanceTotals buildMonthlyReport({
  required int year,
  required int month,
  required List<HistoricoItem> rotasNoMes,
  required List<Gasto> gastosNoMes,
}) {
  var faturamento = 0.0;
  var gastos = 0.0;
  var km = 0.0;
  var entregues = 0;
  for (final r in rotasNoMes) {
    faturamento += r.valorPago;
    gastos += r.gastoTotal;
    km += r.kmRodado;
    entregues += r.entregues;
  }
  final porTipo = <String, double>{};
  for (final g in gastosNoMes) {
    porTipo[g.tipo] = (porTipo[g.tipo] ?? 0) + g.valor;
  }
  return MonthlyFinanceTotals(
    year: year,
    month: month,
    routeCount: rotasNoMes.length,
    faturamento: faturamento,
    gastos: gastos,
    lucro: faturamento - gastos,
    kmRodado: km,
    entregues: entregues,
    gastosPorTipo: porTipo,
  );
}

List<HistoricoItem> historicoOnCalendarDay(List<HistoricoItem> all, DateTime day) {
  return all.where((r) {
    final d = r.deliveryDay;
    return d.year == day.year && d.month == day.month && d.day == day.day;
  }).toList();
}

List<HistoricoItem> historicoInMonth(List<HistoricoItem> all, int year, int month) {
  return all.where((r) {
    final d = r.deliveryDay;
    return d.year == year && d.month == month;
  }).toList();
}

String financeReportPlainText(MonthlyFinanceTotals t, String monthLabel) {
  final buf = StringBuffer()
    ..writeln('ROTA PRIME — Relatório $monthLabel')
    ..writeln('Rotas finalizadas: ${t.routeCount}')
    ..writeln('Entregas: ${t.entregues}')
    ..writeln('KM rodado (odômetro): ${t.kmRodado.toStringAsFixed(1)}')
    ..writeln('Faturamento: R\$ ${t.faturamento.toStringAsFixed(2)}')
    ..writeln('Gastos reais: R\$ ${t.gastos.toStringAsFixed(2)}')
    ..writeln('Lucro líquido: R\$ ${t.lucro.toStringAsFixed(2)}');
  if (t.gastosPorTipo.isNotEmpty) {
    buf.writeln('— Despesas —');
    for (final e in t.gastosPorTipo.entries) {
      buf.writeln('  ${e.key}: R\$ ${e.value.toStringAsFixed(2)}');
    }
  }
  buf.writeln(
    '\nNota: lucro usa KM final − KM inicial do odômetro e gastos que você lançou '
    '(combustível, pedágio…). Não estima km/l do veículo.',
  );
  return buf.toString();
}
