import 'package:flutter/material.dart';
import 'package:rota_prime/app/app_navigator.dart';
import 'package:rota_prime/screens/importando_screen.dart';

/// Tela cheia no navigator raiz — cobre mapa, botões e rodapé do shell.
Future<void> openImportandoScreen() async {
  final nav = rootNavigator;
  if (nav == null || !nav.mounted) return;
  await nav.pushAndRemoveUntil<void>(
    PageRouteBuilder<void>(
      opaque: true,
      fullscreenDialog: true,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const ImportandoScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    ),
    (route) => route.isFirst,
  );
}
