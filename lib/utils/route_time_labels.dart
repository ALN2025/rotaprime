/// Rótulos de tempo para chips do mapa (estilo Circuit).
class RouteTimeLabels {
  RouteTimeLabels._();

  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0 min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '$m min';
  }

  static String formatElapsed(Duration elapsed) {
    final totalMin = elapsed.inMinutes.clamp(0, 9999);
    return formatMinutes(totalMin);
  }

  /// Chip no topo: tempo decorrido na rota ou estimativa antes de iniciar.
  static String routeChipLabel({
    required bool routeActive,
    DateTime? activeSince,
    required int estimatedMinutes,
  }) {
    if (routeActive && activeSince != null) {
      return '${formatElapsed(DateTime.now().difference(activeSince))} na rota';
    }
    if (estimatedMinutes > 0) {
      return '~${formatMinutes(estimatedMinutes)} est.';
    }
    return 'Tempo —';
  }
}
