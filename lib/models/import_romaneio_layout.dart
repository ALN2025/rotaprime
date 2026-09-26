/// Como pin do mapa e chip do pacote usam números do arquivo importado.
enum ImportRomaneioLayout {
  /// Planilha genérica: pin = ordem na rota (1…N).
  padrao,

  /// Shopee: pin e sacola = **ordem do pacote** no romaneio (coluna Sequence).
  shopeeOrdemPacote,

  /// Relatório de entregas (PDF): pin = ordem na rota; info = **ID do pacote**.
  pdfRelatorioRj,

  /// Magalog — PDF “Protocolo de Carregamento”: pin = ordem na rota; chip = **Nº entrega**.
  pdfProtocoloEntrega,
}
