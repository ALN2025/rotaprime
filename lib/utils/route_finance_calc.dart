/// Cálculo financeiro real da rota (km, faturamento, gastos, lucro).
class RouteFinanceSummary {
  const RouteFinanceSummary({
    required this.kmInicial,
    required this.kmFinal,
    required this.valorRota,
    required this.gastoTotal,
    required this.kmRodado,
    required this.lucroLiquido,
    required this.lucroPorKm,
    required this.lucroPorEntrega,
    required this.custoPorKm,
    required this.entregues,
  });

  final double kmInicial;
  final double? kmFinal;
  final double valorRota;
  final double gastoTotal;
  final double kmRodado;
  final double lucroLiquido;
  final double lucroPorKm;
  final double lucroPorEntrega;
  final double custoPorKm;
  final int entregues;
}

RouteFinanceSummary computeRouteFinance({
  required double kmInicial,
  required double? kmFinal,
  required double valorRota,
  required double gastoTotal,
  required int entregues,
}) {
  final kmF = kmFinal;
  var kmRodado = kmF != null ? kmF - kmInicial : 0.0;
  if (kmRodado < 0) kmRodado = 0;
  final lucroLiquido = valorRota - gastoTotal;
  final lucroPorKm = kmRodado > 0 ? lucroLiquido / kmRodado : 0.0;
  final lucroPorEntrega = entregues > 0 ? lucroLiquido / entregues : 0.0;
  final custoPorKm = kmRodado > 0 ? gastoTotal / kmRodado : 0.0;

  return RouteFinanceSummary(
    kmInicial: kmInicial,
    kmFinal: kmFinal,
    valorRota: valorRota,
    gastoTotal: gastoTotal,
    kmRodado: kmRodado,
    lucroLiquido: lucroLiquido,
    lucroPorKm: lucroPorKm,
    lucroPorEntrega: lucroPorEntrega,
    custoPorKm: custoPorKm,
    entregues: entregues,
  );
}

double parseMoneyOrKm(String raw) {
  var t = raw.trim().replaceAll(RegExp(r'[R$\s]'), '');
  if (t.contains(',') && t.contains('.')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (t.contains(',')) {
    t = t.replaceAll(',', '.');
  }
  return double.tryParse(t) ?? 0;
}
