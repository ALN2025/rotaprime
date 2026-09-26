import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aba selecionada no rodapé: 0 Mapa, 1 Rotas, 2 Entregas, 3 Mais.
final appShellTabIndexProvider = StateProvider<int>((ref) => 0);

/// Abrir entrega ativa já com parada focada (lista Entregues / Não deu).
final mapFocusParadaIdProvider = StateProvider<int?>((ref) => null);

void switchAppShellTab(WidgetRef ref, int index) {
  ref.read(appShellTabIndexProvider.notifier).state = index.clamp(0, 3);
}
