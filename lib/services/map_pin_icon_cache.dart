import 'package:flutter/material.dart';
import 'package:rota_prime/utils/parada_labels.dart';

/// Estilos de pin pré-carregados (~32 px no mapa).
///
/// Equivalente ao `Map<String, BitmapDescriptor>` do Google Maps — aqui usamos
/// [TextStyle] porque o ROTA PRIME renderiza pins com [FlutterMap] + widgets.
class MapPinIconCache {
  final Map<String, TextStyle> cache = {};

  void preload() {
    cache['pin32'] = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1,
    );
    cache['pin32_selected'] = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1,
    );
    cache['pin32_compact'] = const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1,
    );
    cache[ParadaLabels.latePackageMarker] = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.amber,
      height: 1,
    );
    cache['cluster'] = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      height: 1,
    );
  }
}
