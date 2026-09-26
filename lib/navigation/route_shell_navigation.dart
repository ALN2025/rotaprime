import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/app_navigator.dart';
import 'package:rota_prime/providers/app_shell_provider.dart';

/// Sinal one-shot: abrir busca ao exibir aba Mapa no shell.
final mapTabOpenSearchProvider = StateProvider<bool>((ref) => false);

BuildContext _navContext(BuildContext context) => rootAppContext ?? context;

/// Volta à tela raiz (shell após o bootstrap).
void popToAppShell(BuildContext context) {
  final nav = Navigator.of(_navContext(context));
  if (nav.canPop()) {
    nav.popUntil((route) => route.isFirst);
  }
}

/// Rota carregada → aba **Mapa** com rodapé visível.
void navigateToRouteMap(
  BuildContext context,
  WidgetRef ref, {
  bool openSearch = false,
}) {
  if (openSearch) {
    ref.read(mapTabOpenSearchProvider.notifier).state = true;
  }
  switchAppShellTab(ref, 0);
  popToAppShell(context);
}

/// Entrega ativa → aba **Mapa** (UI Circuit no shell).
void navigateToActiveDelivery(BuildContext context, WidgetRef ref) {
  navigateToRouteMap(context, ref);
}
