import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_core.dart';
import 'package:rota_prime/utils/limpar_endereco.dart';
import 'package:rota_prime/utils/manual_address_format.dart';

class GeocodeResult {
  GeocodeResult({
    required this.lat,
    required this.lng,
    this.found = true,
  });

  final double lat;
  final double lng;
  final bool found;

  static const fallbackLat = -29.1678;
  static const fallbackLng = -51.1794;

  factory GeocodeResult.fallback() => GeocodeResult(
        lat: fallbackLat,
        lng: fallbackLng,
        found: false,
      );
}

/// Dados estruturados para geocodificar parada manual (CEP ou endereço completo).
class ManualGeocodeInput {
  const ManualGeocodeInput({
    this.street,
    this.number,
    this.neighborhood,
    this.city,
    this.stateUf,
    this.postalCode,
    this.freeform,
  });

  final String? street;
  final String? number;
  final String? neighborhood;
  final String? city;
  final String? stateUf;
  final String? postalCode;
  final String? freeform;

  String get cityHint {
    final c = city?.trim() ?? '';
    final uf = stateUf?.trim() ?? '';
    if (c.isEmpty) return '';
    if (uf.isEmpty) return c;
    return '$c/$uf';
  }
}

class GeocodeService {
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, GeocodeResult> _importCache = {};

  Future<void> _respectRateLimit() async {
    final elapsed = DateTime.now().difference(_lastRequest);
    if (elapsed.inMilliseconds < 1100) {
      await Future<void>.delayed(Duration(milliseconds: 1100 - elapsed.inMilliseconds));
    }
    _lastRequest = DateTime.now();
  }

  /// Localiza endereço no mapa. [allowFallback]: centro genérico só se true (importação).
  Future<GeocodeResult> geocode(
    String endereco, {
    bool allowFallback = true,
    String? cityHint,
  }) async {
    final trimmed = endereco.trim();
    if (trimmed.isEmpty) {
      return allowFallback ? GeocodeResult.fallback() : GeocodeResult.fallback();
    }

    final cityToken = cityHint != null && cityHint.trim().isNotEmpty
        ? cityGeocodeToken(cityHint)
        : '';

    final variants = _queryVariants(trimmed, cityHint: cityHint);
    for (final query in variants) {
      final hit = await _nominatimSearch(query, cityToken: cityToken);
      if (hit != null) return hit;
    }

    final photonHit = await _photonSearch(
      limparEndereco(trimmed, defaultCity: cityHint ?? ''),
      cityToken: cityToken,
    );
    if (photonHit != null) return photonHit;

    for (final query in variants) {
      final hit = await _photonSearch(query, cityToken: cityToken);
      if (hit != null) return hit;
    }

    return allowFallback ? GeocodeResult.fallback() : GeocodeResult.fallback();
  }

  void clearImportGeocodeCache() => _importCache.clear();

  /// Importação em lote: no máximo 2 consultas por endereço + cache na sessão.
  Future<GeocodeResult> geocodeParadaForImport(Parada p) async {
    final key = '${p.zipcode}|${p.destinationAddress}|${p.city}'.toLowerCase();
    final cached = _importCache[key];
    if (cached != null) return cached;

    final query = geocodeQueryForParada(p);
    if (query.isEmpty) {
      final miss = GeocodeResult.fallback();
      _importCache[key] = miss;
      return miss;
    }

    final loc = paradaCityAndUf(p);
    final norm = normalizeAddressToken(addressTextForParada(p));
    final street = extractStreetLine(norm);
    final number = extractPrimaryStreetNumber(norm);
    final zip = p.zipcode.replaceAll(RegExp(r'\D'), '');

    GeocodeResult? hit;
    if (street != null && number != null && loc.city.isNotEmpty) {
      final structured = await _nominatimStructured(
        street: street,
        city: loc.city,
        state: loc.uf.isNotEmpty ? loc.uf : null,
        postalcode: zip.length == 8 ? zip : null,
        housenumber: number,
      );
      if (structured != null) hit = structured;
    }

    hit ??= await _nominatimSearch(
      query,
      cityToken: cityGeocodeToken(loc.city),
    );
    if (hit == null || !hit.found) {
      hit = await _photonSearch(
        limparEndereco(query, defaultCity: loc.city.isNotEmpty ? '${loc.city}/${loc.uf}' : ''),
        cityToken: cityGeocodeToken(loc.city),
      );
    }

    final result = (hit != null && hit.found) ? hit : GeocodeResult.fallback();
    if (result.found) {
      _importCache[key] = result;
    }
    return result;
  }

  /// Planilha / romaneio: rua + número + CEP (sem nome do destinatário).
  Future<GeocodeResult> geocodeParada(Parada p, {bool allowFallback = true}) async {
    final query = geocodeQueryForParada(p);
    if (query.isEmpty) {
      return allowFallback ? GeocodeResult.fallback() : GeocodeResult.fallback();
    }

    final norm = normalizeAddressToken(addressTextForParada(p));
    final street = extractStreetLine(norm);
    final number = extractPrimaryStreetNumber(norm);
    final loc = paradaCityAndUf(p);
    final zip = p.zipcode.replaceAll(RegExp(r'\D'), '');

    if (street != null && number != null && loc.city.isNotEmpty) {
      final structured = await _nominatimStructured(
        street: street,
        city: loc.city,
        state: loc.uf.isNotEmpty ? loc.uf : null,
        postalcode: zip.length == 8 ? zip : null,
        housenumber: number,
      );
      if (structured != null) return structured;
    }

    if (zip.length == 8) {
      final cepQuery = loc.uf.isNotEmpty ? '$zip, ${loc.uf}, Brasil' : '$zip, Brasil';
      final byCep = await _nominatimSearch(
        cepQuery,
        cityToken: cityGeocodeToken(loc.city),
      );
      if (byCep != null && byCep.found) return byCep;
    }

    return geocode(
      query,
      allowFallback: allowFallback,
      cityHint: loc.city.isNotEmpty ? '${loc.city}/${loc.uf}' : null,
    );
  }

  /// Parada manual: tenta número exato (CEP+nº), depois a rua na cidade.
  Future<GeocodeResult> geocodeManualStop(
    ManualGeocodeInput input, {
    bool allowStreetFallback = true,
  }) async {
    final cityHint = input.cityHint.isNotEmpty ? input.cityHint : input.city;
    final street = input.street?.trim() ?? '';
    final number = input.number?.trim() ?? '';
    final freeform = input.freeform?.trim() ?? '';

    if (street.isNotEmpty && input.city?.trim().isNotEmpty == true) {
      final structured = await _nominatimStructured(
        street: street,
        city: input.city!.trim(),
        state: input.stateUf?.trim(),
        postalcode: input.postalCode?.replaceAll(RegExp(r'\D'), ''),
        housenumber: number.isNotEmpty ? number : null,
      );
      if (structured != null) return structured;

      if (number.isNotEmpty) {
        final withNumber = await geocode(
          '$street, $number, ${input.neighborhood ?? ''}, ${input.cityHint}, Brasil',
          allowFallback: false,
          cityHint: cityHint,
        );
        if (withNumber.found) return withNumber;
      }
    }

    if (freeform.isNotEmpty) {
      final fromText = await geocode(
        freeform,
        allowFallback: false,
        cityHint: cityHint,
      );
      if (fromText.found) return fromText;
    }

    if (allowStreetFallback &&
        street.isNotEmpty &&
        input.city?.trim().isNotEmpty == true) {
      final onStreet = await _geocodeStreetInCity(
        street: street,
        city: input.city!.trim(),
        state: input.stateUf?.trim(),
        cityHint: cityHint,
      );
      if (onStreet != null) return onStreet;
    }

    return GeocodeResult.fallback();
  }

  Future<GeocodeResult?> _nominatimStructured({
    required String street,
    required String city,
    String? state,
    String? postalcode,
    String? housenumber,
  }) async {
    try {
      await _respectRateLimit();
      final params = <String, String>{
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'br',
        'addressdetails': '1',
        'street': street,
        'city': city,
        'country': 'Brasil',
      };
      if (state != null && state.isNotEmpty) params['state'] = state;
      if (postalcode != null && postalcode.length == 8) {
        params['postalcode'] = postalcode;
      }
      if (housenumber != null && housenumber.isNotEmpty) {
        params['housenumber'] = housenumber;
      }
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'RotaPrime/1.0 (delivery-route-app)'},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;
      final cityToken = cityGeocodeToken(city);
      final best = _pickBestNominatimHit(
        list,
        cityToken: cityToken,
        relaxCityFilter: true,
      );
      if (best == null) return null;
      return GeocodeResult(
        lat: double.parse(best['lat'] as String),
        lng: double.parse(best['lon'] as String),
        found: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<GeocodeResult?> _geocodeStreetInCity({
    required String street,
    required String city,
    String? state,
    String? cityHint,
  }) async {
    final hint = cityHint ?? city;
    final q = state != null && state.isNotEmpty
        ? '$street, $city, $state, Brasil'
        : '$street, $city, Brasil';
    final hit = await _nominatimSearch(q, cityToken: cityGeocodeToken(hint));
    if (hit != null) return hit;
    return _photonSearch(q, cityToken: cityGeocodeToken(hint));
  }

  List<String> _queryVariants(String raw, {String? cityHint}) {
    final defaultCity = cityHint?.trim().isNotEmpty == true ? cityHint!.trim() : '';
    final out = <String>{};
    out.add(limparEndereco(raw, defaultCity: defaultCity));
    out.add(raw);
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isNotEmpty) out.add('$cleaned, Brasil');
    return out.where((q) => q.trim().length >= 4).toList();
  }

  Future<GeocodeResult?> _nominatimSearch(
    String query, {
    String cityToken = '',
  }) async {
    try {
      await _respectRateLimit();
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '8',
        'countrycodes': 'br',
        'addressdetails': '1',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'RotaPrime/1.0 (delivery-route-app)'},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;
      final best = _pickBestNominatimHit(list, cityToken: cityToken);
      if (best == null) return null;
      return GeocodeResult(
        lat: double.parse(best['lat'] as String),
        lng: double.parse(best['lon'] as String),
        found: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<GeocodeResult?> _photonSearch(
    String query, {
    String cityToken = '',
  }) async {
    try {
      final uri = Uri.https('photon.komoot.io', '/api/', {
        'q': query,
        'limit': '6',
        'lang': 'default',
      });
      final response = await http
          .get(uri, headers: {'User-Agent': 'RotaPrime/1.0'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final features = body['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) return null;
      final best = _pickBestPhotonHit(features, cityToken: cityToken);
      if (best == null) return null;
      final coords = best['geometry']?['coordinates'] as List<dynamic>?;
      if (coords == null || coords.length < 2) return null;
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      return GeocodeResult(lat: lat, lng: lng, found: true);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _pickBestNominatimHit(
    List<dynamic> list, {
    String cityToken = '',
    bool relaxCityFilter = false,
  }) {
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final raw in list) {
      final item = raw as Map<String, dynamic>;
      var score = _nominatimScore(item);
      score += _cityMatchScoreNominatim(item, cityToken);
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    if (cityToken.isNotEmpty && bestScore < 15) {
      if (!relaxCityFilter) return null;
      if (bestScore < -20) return null;
    }
    return bestScore >= 0 ? best : null;
  }

  Map<String, dynamic>? _pickBestPhotonHit(
    List<dynamic> features, {
    String cityToken = '',
  }) {
    Map<String, dynamic>? best;
    var bestScore = -999;
    for (final raw in features) {
      final f = raw as Map<String, dynamic>;
      final props = f['properties'] as Map<String, dynamic>? ?? {};
      var score = 0;
      final type = (props['type'] as String?)?.toLowerCase() ?? '';
      if (type == 'house' || type == 'building') score += 40;
      if (props['housenumber'] != null) score += 30;
      if (props['street'] != null) score += 12;
      if (props['countrycode'] == 'BR') score += 8;
      final imp = props['importance'];
      if (imp is num) score += (imp * 15).round();
      score += _cityMatchScorePhoton(props, cityToken);
      if (score > bestScore) {
        bestScore = score;
        best = f;
      }
    }
    if (cityToken.isNotEmpty && bestScore < 12) return null;
    return bestScore >= 8 ? best : null;
  }

  int _cityMatchScoreNominatim(Map<String, dynamic> item, String cityToken) {
    if (cityToken.isEmpty) return 0;
    final blob = _nominatimCityBlob(item);
    if (blob.contains(cityToken)) return 45;
    return -80;
  }

  int _cityMatchScorePhoton(Map<String, dynamic> props, String cityToken) {
    if (cityToken.isEmpty) return 0;
    final parts = <String>[
      props['city'] as String? ?? '',
      props['county'] as String? ?? '',
      props['state'] as String? ?? '',
      props['name'] as String? ?? '',
    ];
    final blob = parts.join(' ').toLowerCase();
    if (blob.contains(cityToken)) return 45;
    return -80;
  }

  String _nominatimCityBlob(Map<String, dynamic> item) {
    final chunks = <String>[
      item['display_name'] as String? ?? '',
    ];
    final addr = item['address'];
    if (addr is Map) {
      for (final key in ['city', 'town', 'village', 'municipality', 'county', 'state']) {
        final v = addr[key];
        if (v != null) chunks.add(v.toString());
      }
    }
    return chunks.join(' ').toLowerCase();
  }

  int _nominatimScore(Map<String, dynamic> item) {
    var score = 0;
    final type = (item['type'] as String?)?.toLowerCase() ?? '';
    final clazz = (item['class'] as String?)?.toLowerCase() ?? '';
    if (clazz == 'building' || type == 'house' || type == 'residential') {
      score += 40;
    } else if (clazz == 'place' && type == 'house') {
      score += 35;
    } else if (clazz == 'highway') {
      score -= 15;
    } else if (clazz == 'place' && (type == 'city' || type == 'town')) {
      score -= 25;
    }
    final imp = item['importance'];
    if (imp is num) {
      score += (imp * 20).round();
    }
    final addr = item['address'];
    if (addr is Map) {
      if (addr['house_number'] != null) score += 25;
      if (addr['road'] != null) score += 10;
    }
    return score;
  }
}
