enum MapBasemap {
  standard(
    label: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: null,
    maxNativeZoom: 19,
  ),
  streets(
    label: 'Ruas (recomendado)',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    subdomains: null,
    maxNativeZoom: 19,
  ),
  satellite(
    label: 'Satélite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    labelOverlays: [
      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}',
      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
    ],
    subdomains: null,
    maxNativeZoom: 19,
    labelsMaxNativeZoom: 19,
  ),
  terrain(
    label: 'Relevo',
    urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    subdomains: null,
    maxNativeZoom: 17,
  ),
  /// Esri Canvas (sem API key) — base + camada Reference com nomes de ruas.
  dark(
    label: 'Escuro (usa ruas)',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    labelOverlays: [
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
    ],
    subdomains: null,
    maxNativeZoom: 16,
    labelsMaxNativeZoom: 16,
  );

  const MapBasemap({
    required this.label,
    required this.urlTemplate,
    required this.subdomains,
    required this.maxNativeZoom,
    this.labelOverlays,
    this.labelsMaxNativeZoom,
    this.retinaOnServer = false,
  });

  final String label;
  final String urlTemplate;
  final List<String>? subdomains;
  final int maxNativeZoom;
  final List<String>? labelOverlays;
  final int? labelsMaxNativeZoom;
  final bool retinaOnServer;

  String? get labelsUrlTemplate {
    final layers = labelOverlays;
    if (layers == null || layers.isEmpty) return null;
    return layers.first;
  }

  String tileCacheFolder({required bool labels, int labelIndex = 0}) {
    if (name == 'dark' && !labels) return 'dark_esri';
    if (name == 'dark' && labels) return 'dark_esri_labels';
    if (labels) {
      return labelIndex == 0 ? '${name}_labels' : '${name}_labels_$labelIndex';
    }
    return name;
  }

  static String expandTileUrl(String template) {
    return template.replaceAll('{r}', '');
  }

  static const double appMaxZoom = 20;

  static MapBasemap get navigationPreferred => MapBasemap.streets;
}
