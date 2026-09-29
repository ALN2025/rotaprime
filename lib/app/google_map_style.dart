/// Estilo escuro oficial (rótulos de ruas visíveis).
const String kGoogleMapDarkStyleJson = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d1d1d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1d1d1d"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2c2c2c"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9a9a9a"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#373737"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3d3d3d"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#bdbdbd"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f2f2f"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]}
]
''';
