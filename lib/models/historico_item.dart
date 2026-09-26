class HistoricoItem {
  HistoricoItem({
    required this.id,
    required this.titulo,
    required this.paradasCount,
    required this.criadaEm,
    this.finalizadaEm,
    this.valorPago = 0,
    this.gastoTotal = 0,
    this.kmInicial = 0,
    this.kmFinal,
    this.kmRodado = 0,
    this.lucroLiquido = 0,
    this.entregues = 0,
  });

  final int id;
  final String titulo;
  final int paradasCount;
  final DateTime criadaEm;
  final DateTime? finalizadaEm;
  final double valorPago;
  final double gastoTotal;
  final double kmInicial;
  final double? kmFinal;
  final double kmRodado;
  final double lucroLiquido;
  final int entregues;

  /// Dia da entrega (finalização da rota).
  DateTime get deliveryDay {
    final d = finalizadaEm ?? criadaEm;
    return DateTime(d.year, d.month, d.day);
  }
}
