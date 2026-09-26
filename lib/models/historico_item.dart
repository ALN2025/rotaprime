class HistoricoItem {
  HistoricoItem({
    required this.id,
    required this.titulo,
    required this.paradasCount,
    required this.criadaEm,
    this.finalizadaEm,
  });

  final int id;
  final String titulo;
  final int paradasCount;
  final DateTime criadaEm;
  final DateTime? finalizadaEm;
}
