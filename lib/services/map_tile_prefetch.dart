import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/services/settings_persistence.dart';
import 'package:rota_prime/services/user_prefs_service.dart';

const _tileUserAgent =
    'ROTA_PRIME/1.0 (+https://rotaprime.app; com.rotaprime.rota_prime)';

/// Baixa tiles do mapa na área da rota para uso offline parcial.
class MapTilePrefetch {
  MapTilePrefetch._();

  /// Caminho do cache após o primeiro [cacheDirectory] (leitura síncrona no mapa).
  static String? cacheRootSync;

  static int _legacyDarkCachePurgedGen = 0;
  static const _legacyPurgeGeneration = 5;

  /// Apaga pastas antigas (Carto/Google/Esri Dark Gray sem ruas no zoom).
  static void purgeLegacyDarkTileCaches(String cacheRoot) {
    if (_legacyDarkCachePurgedGen >= _legacyPurgeGeneration) return;
    _legacyDarkCachePurgedGen = _legacyPurgeGeneration;
    const legacy = <String>[
      'dark',
      'dark_carto_osm',
      'dark_carto_osm_v2',
      'dark_carto_osm_labels_v2',
      'dark_esri_base_v3',
      'dark_esri_ref_v3',
    ];
    for (final folder in legacy) {
      try {
        final d = Directory('$cacheRoot/$folder');
        if (d.existsSync()) d.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  static Future<String> cacheDirectory() async {
    if (cacheRootSync != null) return cacheRootSync!;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/map_tiles');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    cacheRootSync = dir.path;
    purgeLegacyDarkTileCaches(cacheRootSync!);
    return cacheRootSync!;
  }

  static Future<void> prefetchAllBasemapsForRoute({
    required List<Parada> paradas,
    int minZoom = 14,
    int maxZoom = 17,
    void Function(String message)? onProgress,
  }) async {
    for (final basemap in MapBasemap.values) {
      onProgress?.call('Mapa offline (${basemap.label})…');
      await prefetchForRoute(
        paradas: paradas,
        basemap: basemap,
        minZoom: minZoom,
        maxZoom: maxZoom,
      );
    }
    onProgress?.call('Mapas da rota salvos para uso offline');
  }

  /// Apenas o estilo escolhido em Configurações — menos rede, disco e RAM.
  static Future<void> prefetchUserBasemapForRoute({
    required List<Parada> paradas,
    required MapBasemap basemap,
    int minZoom = 14,
    int maxZoom = 16,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Mapa offline (${basemap.label})…');
    await prefetchForRoute(
      paradas: paradas,
      basemap: basemap,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    onProgress?.call('Mapa da rota salvo para uso offline');
  }

  /// Mapa salvo nas preferências do aparelho (após importar rota).
  static Future<void> prefetchDeviceBasemapForParadas(List<Parada> paradas) async {
    final json = await UserPrefsService().load(kLocalSettingsKey);
    final basemap = UserPrefsService().mapSettingsFromJson(json).basemap;
    await prefetchForRoute(paradas: paradas, basemap: basemap, maxZoom: 15);
  }

  static Future<void> prefetchForRoute({
    required List<Parada> paradas,
    MapBasemap basemap = MapBasemap.streets,
    int minZoom = 14,
    int maxZoom = 15,
    void Function(String message)? onProgress,
  }) async {
    final points = <LatLng>[];
    for (final p in paradas) {
      if (p.latitude != null && p.longitude != null) {
        points.add(LatLng(p.latitude!, p.longitude!));
      }
    }
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;
    for (final pt in points) {
      minLat = math.min(minLat, pt.latitude);
      maxLat = math.max(maxLat, pt.latitude);
      minLng = math.min(minLng, pt.longitude);
      maxLng = math.max(maxLng, pt.longitude);
    }
    const pad = 0.012;
    minLat -= pad;
    maxLat += pad;
    minLng -= pad;
    maxLng += pad;

    final cacheRoot = await cacheDirectory();
    var downloaded = 0;
    downloaded += await _prefetchTemplate(
      cacheRoot: cacheRoot,
      cacheFolder: basemap.tileCacheFolder(labels: false),
      basemap: basemap,
      minLat: minLat,
      minLng: minLng,
      maxLat: maxLat,
      maxLng: maxLng,
      minZoom: minZoom,
      maxZoom: maxZoom,
      onProgress: onProgress,
      downloadedSoFar: downloaded,
    );
    final overlays = basemap.labelOverlays ?? const [];
    for (var i = 0; i < overlays.length; i++) {
      downloaded += await _prefetchTemplate(
        cacheRoot: cacheRoot,
        cacheFolder: basemap.tileCacheFolder(labels: true, labelIndex: i),
        basemap: basemap,
        urlTemplateOverride: overlays[i],
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
        minZoom: minZoom,
        maxZoom: math.min(maxZoom, basemap.labelsMaxNativeZoom ?? maxZoom),
        onProgress: onProgress,
        downloadedSoFar: downloaded,
      );
    }
    onProgress?.call('Mapa da rota salvo ($downloaded tiles novos)');
  }
}

Future<int> _prefetchTemplate({
  required String cacheRoot,
  required String cacheFolder,
  required MapBasemap basemap,
  String? urlTemplateOverride,
  required double minLat,
  required double minLng,
  required double maxLat,
  required double maxLng,
  required int minZoom,
  required int maxZoom,
  void Function(String message)? onProgress,
  required int downloadedSoFar,
}) async {
  var downloaded = 0;
  for (var z = minZoom; z <= maxZoom; z++) {
    final tiles = _tilesForBounds(minLat, minLng, maxLat, maxLng, z);
    for (final t in tiles) {
      final path = '$cacheRoot/$cacheFolder/$z/${t.x}/${t.y}.png';
      final file = File(path);
      if (file.existsSync()) continue;
      final url = urlTemplateOverride == null
          ? basemap.tileUrlFor(z, t.x, t.y)
          : MapBasemap.resolveTileUrlTemplate(
              urlTemplateOverride,
              z,
              t.x,
              t.y,
              subdomains: basemap.subdomains,
            );
      try {
        final res = await http.get(
          Uri.parse(url),
          headers: const {'User-Agent': _tileUserAgent},
        );
        if (res.statusCode == 200 && _looksLikePng(res.bodyBytes)) {
          file.parent.createSync(recursive: true);
          await file.writeAsBytes(res.bodyBytes);
          downloaded++;
          if ((downloadedSoFar + downloaded) % 40 == 0) {
            onProgress?.call('Mapa offline: ${downloadedSoFar + downloaded} tiles…');
          }
        }
      } catch (_) {}
    }
  }
  return downloaded;
}

class _TileCoord {
  _TileCoord(this.x, this.y);
  final int x;
  final int y;
}

List<_TileCoord> _tilesForBounds(
  double minLat,
  double minLng,
  double maxLat,
  double maxLng,
  int z,
) {
  final x0 = _lonToTileX(minLng, z);
  final x1 = _lonToTileX(maxLng, z);
  final y0 = _latToTileY(maxLat, z);
  final y1 = _latToTileY(minLat, z);
  final out = <_TileCoord>[];
  for (var x = x0; x <= x1; x++) {
    for (var y = y0; y <= y1; y++) {
      out.add(_TileCoord(x, y));
    }
  }
  return out;
}

int _lonToTileX(double lon, int z) {
  return ((lon + 180) / 360 * (1 << z)).floor();
}

bool _looksLikePng(List<int> bytes) {
  if (bytes.length < 600) return false;
  if (bytes.length < 8) return false;
  return bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
}

int _latToTileY(double lat, int z) {
  final latRad = lat * math.pi / 180;
  return ((1 -
              (math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi)) /
          2 *
          (1 << z))
      .floor();
}
