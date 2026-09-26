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
    super.headers,
  });

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
    final path = _localPath(coordinates);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return _network.getImage(coordinates, options);
  }

  @override
  Future<void> dispose() async {
    await _network.dispose();
    super.dispose();
  }
}
