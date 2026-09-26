import 'dart:convert';

/// Decodifica geometria da rota (use [compute] se o JSON for grande).
List<List<double>> decodeRouteGeometryPairs(String json) {
  if (json.isEmpty) return const [];
  final list = jsonDecode(json) as List<dynamic>;
  return list
      .map((e) => [(e[0] as num).toDouble(), (e[1] as num).toDouble()])
      .toList();
}
