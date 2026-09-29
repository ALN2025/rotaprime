/// Limites de performance do mapa / planejamento (ultra rápido no celular).
class MapPerformance {
  MapPerformance._();

  /// Abre a **lista** primeiro — mapa regional fica atrás, sem travar.
  static const listFirstStopCount = 40;

  /// Pins leves, tiles só rede, basemap simples.
  static const heavyStopCount = 25;

  /// Linha laranja completa só abaixo disso.
  static const maxStopsFullPolyline = 40;
}
