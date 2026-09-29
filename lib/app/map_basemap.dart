enum MapBasemap {
  standard(
    label: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: null,
    maxNativeZoom: 19,
  ),
  streets(
    label: 'Ruas (recomendado)',
    urlTemplate: _esriWorldStreetUrl,
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
  /// Carto Dark — fundo escuro de verdade + nomes de ruas no tile (zoom como apps Spok-like).
  dark(
    label: 'Escuro',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    subdomains: _cartoSubdomains,
    maxNativeZoom: 19,
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
    if (name == 'dark' && !labels) return 'dark_carto_all_v6';
    if (labels) {
      return labelIndex == 0 ? '${name}_labels' : '${name}_labels_$labelIndex';
    }
    return name;
  }

  static const _esriWorldStreetUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';

  static const List<String> _cartoSubdomains = ['a', 'b', 'c', 'd'];

  static String expandTileUrl(String template) {
    return template.replaceAll('{r}', '');
  }

  String tileUrlFor(int z, int x, int y) {
    return resolveTileUrlTemplate(
      urlTemplate,
      z,
      x,
      y,
      subdomains: subdomains,
    );
  }

  static String resolveTileUrlTemplate(
    String template,
    int z,
    int x,
    int y, {
    List<String>? subdomains,
  }) {
    var url = template.replaceAll('{r}', '');
    final subs = subdomains;
    final sub = subs != null && subs.isNotEmpty
        ? subs[(x + y + z) % subs.length]
        : 'a';
    return url
        .replaceAll('{s}', sub)
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
  }

  static const double appMaxZoom = 20;

  static MapBasemap get navigationPreferred => MapBasemap.streets;

  static const List<MapBasemap> userChoices = [MapBasemap.streets, MapBasemap.dark];

  static MapBasemap normalizeSaved(MapBasemap saved) {
    if (saved == MapBasemap.dark) return MapBasemap.dark;
    return MapBasemap.streets;
  }

  /// Ruas e Escuro usam Google Maps SDK (nomes de ruas nativos).
  static bool usesGoogleMaps(MapBasemap basemap) =>
      basemap == MapBasemap.streets || basemap == MapBasemap.dark;

  /// Mapa escuro (Google estilo night) — recurso PRO / trial PRO.
  static bool requiresPro(MapBasemap basemap) => basemap == MapBasemap.dark;

  static MapBasemap effectiveForPlan(MapBasemap saved, {required bool isPro}) {
    final normalized = normalizeSaved(saved);
    if (requiresPro(normalized) && !isPro) return MapBasemap.streets;
    return normalized;
  }

  String get userChoiceLabel => switch (this) {
        MapBasemap.dark => 'Escuro',
        MapBasemap.streets => 'Ruas',
        _ => label,
      };
}
