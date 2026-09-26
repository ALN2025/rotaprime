String normalizeHeader(String h) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  var s = h.toLowerCase();
  for (final e in accents.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String? pickCell(Map<String, String> cells, List<String> aliases) {
  final normalized = <String, String>{
    for (final e in cells.entries) normalizeHeader(e.key): e.value,
  };
  for (final alias in aliases) {
    final key = normalizeHeader(alias);
    final v = normalized[key];
    if (v != null && v.trim().isNotEmpty) return v.trim();
  }
  for (final entry in normalized.entries) {
    for (final alias in aliases) {
      final key = normalizeHeader(alias);
      if (key.length < 4) continue;
      if (entry.key.contains(key) && entry.value.trim().isNotEmpty) {
        return entry.value.trim();
      }
    }
  }
  return null;
}

const spxAliases = [
  'SPX TN',
  'SPX',
  'Tracking',
  'TN',
  'Package ID',
  'AT ID',
  'Nº Entrega',
  'No Entrega',
  'Código de Barras',
  'Codigo de Barras',
  'ID do Pacote',
];
const addressAliases = [
  'Destination Address',
  'Address',
  'Endereço',
  'Endereco',
  'Endereço Completo',
  'Endereco Completo',
  'Rua',
];
const sequenceAliases = [
  'Sequence',
  'Seq',
  'Ordem',
  'Order',
  'Número ordem',
  'Numero ordem',
  'Nº ordem',
  'Pacote',
  'Package',
  'Package Number',
  'Número do pacote',
  'Numero do pacote',
  'Nº Entrega',
  'No Entrega',
  'ID do Pacote',
  'Nº Pedido',
  'No Pedido',
];
const stopAliases = [
  'Stop',
  'Parada',
  'Stop Number',
  'Número da parada',
  'Numero da parada',
];
const bairroAliases = ['Bairro', 'Neighborhood', 'District'];
const cityAliases = ['City', 'Cidade', 'Cidade/UF'];
const zipAliases = ['Zipcode', 'Zip', 'CEP'];
const latAliases = ['Latitude', 'Lat'];
const lngAliases = ['Longitude', 'Lng', 'Lon'];
const packageQtyAliases = [
  'Package Qty',
  'Packages',
  'Pacotes',
  'Quantidade',
  'Qty',
  'Quantity',
  'Piece Count',
  'Parcels',
];

const deliveryStatusAliases = [
  'Status',
  'Delivery Status',
  'Order Status',
  'Parcel Status',
  'Estado',
  'Situacao',
  'Situação',
  'Status entrega',
  'Delivery state',
];

const deliveredFlagAliases = [
  'Delivered',
  'Entregue',
  'Is Delivered',
  'Completed',
  'Concluido',
  'Concluído',
];

/// Campos fixos da tela de mapeamento → aliases na planilha real.
const importFieldAliasMap = <String, List<String>>{
  'AT ID': ['AT ID', 'AT'],
  'Sequence': sequenceAliases,
  'Stop': stopAliases,
  'SPX TN': spxAliases,
  'Destination Address': addressAliases,
  'Bairro': bairroAliases,
  'City': cityAliases,
  'Zipcode': zipAliases,
  'Latitude': latAliases,
  'Longitude': lngAliases,
  'Package Qty': packageQtyAliases,
  'Status': deliveryStatusAliases,
};

/// Converte uma linha da planilha (cabeçalhos reais) para os rótulos do app.
Map<String, String> mapRowCellsToImportFields(Map<String, String> cells) {
  return {
    for (final entry in importFieldAliasMap.entries)
      entry.key: pickCell(cells, entry.value) ?? '',
  };
}

List<Map<String, String>> normalizeImportPreviewRows(List<Map<String, String>> rawRows) {
  return rawRows.map(mapRowCellsToImportFields).toList();
}
