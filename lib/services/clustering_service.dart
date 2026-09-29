import 'dart:math' as math;



import 'package:latlong2/latlong.dart';



/// Ponto leve para viewport (equivalente ao marker do Google Maps).

class ClusterMapPoint {

  const ClusterMapPoint({

    required this.paradaId,

    required this.latitude,

    required this.longitude,

    required this.pinLabel,

  });



  final int paradaId;

  final double latitude;

  final double longitude;

  final String pinLabel;



  LatLng get latLng => LatLng(latitude, longitude);



  Map<String, dynamic> toJson() => {

        'paradaId': paradaId,

        'latitude': latitude,

        'longitude': longitude,

        'pinLabel': pinLabel,

      };



  static ClusterMapPoint fromJson(Map<String, dynamic> json) => ClusterMapPoint(

        paradaId: json['paradaId'] as int,

        latitude: (json['latitude'] as num).toDouble(),

        longitude: (json['longitude'] as num).toDouble(),

        pinLabel: json['pinLabel'] as String? ?? '',

      );

}



/// Pin ou agrupamento (grid ~50 m) para desenhar no mapa.

class MapPinCluster {

  const MapPinCluster({

    required this.representativeParadaId,

    required this.memberParadaIds,

    required this.latitude,

    required this.longitude,

    required this.displayLabel,

    required this.isMergedCluster,

  });



  final int representativeParadaId;

  final List<int> memberParadaIds;

  final double latitude;

  final double longitude;

  final String displayLabel;

  final bool isMergedCluster;



  LatLng get latLng => LatLng(latitude, longitude);

}



MapPinCluster clusterFromPoint(ClusterMapPoint p) => MapPinCluster(

      representativeParadaId: p.paradaId,

      memberParadaIds: [p.paradaId],

      latitude: p.latitude,

      longitude: p.longitude,

      displayLabel: p.pinLabel,

      isMergedCluster: false,

    );



List<MapPinCluster> clustersFromPoints(Iterable<ClusterMapPoint> points) =>

    [for (final p in points) clusterFromPoint(p)];



/// Mantém só pontos dentro da região visível (+ padding).

List<ClusterMapPoint> filtrarPorBounds(

  List<ClusterMapPoint> points, {

  required double south,

  required double north,

  required double west,

  required double east,

  double paddingDegrees = 0.015,

}) {

  final s = south - paddingDegrees;

  final n = north + paddingDegrees;

  final w = west - paddingDegrees;

  final e = east + paddingDegrees;

  return points.where((p) {

    return p.latitude >= s &&

        p.latitude <= n &&

        p.longitude >= w &&

        p.longitude <= e;

  }).toList();

}



String _gridKey(ClusterMapPoint p, double gridMeters) {

  final latStep = gridMeters / 111_000.0;

  final lngStep = gridMeters /

      (111_000.0 *

          math.cos(p.latitude * math.pi / 180).abs().clamp(0.2, 1.0));

  final gi = (p.latitude / latStep).floor();

  final gj = (p.longitude / lngStep).floor();

  return '$gi:$gj';

}



/// O(n) — células de ~50 m. Acima de 40 pontos: sem agrupar (máx. 50 pins).

List<MapPinCluster> clusterizar(

  List<ClusterMapPoint> points, {

  double gridMeters = 50,

  int skipClusterAboveCount = 40,

  int maxPinsWithoutCluster = 50,

}) {

  if (points.isEmpty) return const [];

  if (points.length > skipClusterAboveCount) {
    // Já filtrados pelo viewport — não cortar de novo (sumiam pins).
    return clustersFromPoints(points);
  }

  if (points.length == 1) {

    return [clusterFromPoint(points.first)];

  }



  final buckets = <String, List<ClusterMapPoint>>{};

  for (final p in points) {

    buckets.putIfAbsent(_gridKey(p, gridMeters), () => []).add(p);

  }



  final out = <MapPinCluster>[];

  for (final group in buckets.values) {

    if (group.length == 1) {

      out.add(clusterFromPoint(group.first));

      continue;

    }

    var latSum = 0.0;

    var lngSum = 0.0;

    final ids = <int>[];

    for (final p in group) {

      latSum += p.latitude;

      lngSum += p.longitude;

      ids.add(p.paradaId);

    }

    ids.sort();

    out.add(

      MapPinCluster(

        representativeParadaId: ids.first,

        memberParadaIds: ids,

        latitude: latSum / group.length,

        longitude: lngSum / group.length,

        displayLabel: '${group.length}',

        isMergedCluster: true,

      ),

    );

  }

  return out;

}


