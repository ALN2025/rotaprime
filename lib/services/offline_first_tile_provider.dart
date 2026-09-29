import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/services/map_tile_prefetch.dart';

/// Usa tiles baixados em disco quando existirem; senão busca na rede.
class OfflineFirstTileProvider extends TileProvider {
  OfflineFirstTileProvider({
    required this.basemap,
    this.labelsOverlay = false,
    this.labelOverlayIndex = 0,
    this.preferNetwork = false,
    super.headers,
  });

  /// Rotas grandes: evita existsSync no disco a cada tile (zoom/pan travava).
  final bool preferNetwork;

  static const _tileHeaders = {
    'User-Agent':
        'ROTA_PRIME/1.0 (+https://rotaprime.app; com.rotaprime.rota_prime)',
  };

  final MapBasemap basemap;
  final bool labelsOverlay;
  final int labelOverlayIndex;
  late final NetworkTileProvider _network = NetworkTileProvider(
    headers: {..._tileHeaders, ...headers},
  );

  String? _localPath(TileCoordinates coordinates) {
    final root = MapTilePrefetch.cacheRootSync;
    if (root == null) return null;
    final folder = basemap.tileCacheFolder(
      labels: labelsOverlay,
      labelIndex: labelOverlayIndex,
    );
    return '$root/$folder/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (!preferNetwork) {
      final path = _localPath(coordinates);
      if (path != null) {
        final file = File(path);
        if (file.existsSync() && _isValidMapTileFile(file)) {
          return FileImage(file);
        }
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
      }
    }
    return _network.getImage(coordinates, options);
  }

  static bool _isValidMapTileFile(File file) {
    try {
      final len = file.lengthSync();
      if (len < 600) return false;
      if (len < 8) return false;
      final raf = file.openSync(mode: FileMode.read);
      try {
        final head = raf.readSync(4);
        return head.length == 4 &&
            head[0] == 0x89 &&
            head[1] == 0x50 &&
            head[2] == 0x4E &&
            head[3] == 0x47;
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await _network.dispose();
    super.dispose();
  }
}
