import 'package:flutter/material.dart';

/// Barra Modo mapa / Modo lista (fixa acima do dock).
const kRouteMapModeBarHeight = 52.0;

/// Altura aproximada do topo (toggle + cards), sem SafeArea.
const kDriverRouteTopBarBodyHeight = 96.0;

double driverRouteTopChromeHeight(BuildContext context) {
  return MediaQuery.paddingOf(context).top + kDriverRouteTopBarBodyHeight;
}

/// Alça compacta (GPS / entregue) no modo mapa recolhido.
const kDeliveryPeekBarHeight = 46.0;

double mapFooterReserve({
  required bool hasParadas,
  required bool compactDeliveryDock,
  required bool paradaSelected,
  required bool optimizedRow,
}) {
  if (!hasParadas) return 0;
  final modeBar = kRouteMapModeBarHeight;
  if (compactDeliveryDock) return modeBar + kDeliveryPeekBarHeight;
  return modeBar + mapActionBarReserve(
        paradaSelected: paradaSelected,
        optimizedRow: optimizedRow,
      );
}

double mapFloatingControlsBottom({
  required double sheetChromeBottom,
  required double sheetAreaHeight,
  required double sheetSize,
  double gap = 16,
}) {
  return sheetChromeBottom + (sheetAreaHeight * sheetSize).clamp(0, sheetAreaHeight) + gap;
}

/// Reserva vertical para a faixa de ações fixa (incl. SafeArea interna do dock).
const kMapPlanningActionBarHeight = 152.0;
const kMapStopActionBarHeight = 142.0;
const kMapOptimizedRowHeight = 132.0;

double mapScreenBottomInset(BuildContext context, {required bool embeddedInShell}) {
  if (embeddedInShell) return 0;
  return MediaQuery.paddingOf(context).bottom;
}

double mapActionBarReserve({required bool paradaSelected, required bool optimizedRow}) {
  if (paradaSelected) return kMapStopActionBarHeight;
  if (optimizedRow) return kMapOptimizedRowHeight;
  return kMapPlanningActionBarHeight;
}
