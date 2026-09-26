import 'package:flutter/material.dart';

/// Navegação global — sobrevive ao fechar telas/modais (ex.: Criar rota + file picker).
final rootNavigatorKey = GlobalKey<NavigatorState>();

BuildContext? get rootAppContext => rootNavigatorKey.currentContext;

NavigatorState? get rootNavigator => rootNavigatorKey.currentState;
