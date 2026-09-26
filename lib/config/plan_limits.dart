class PlanLimits {
  PlanLimits._();
  /// PRO completo nos primeiros dias (por aparelho, sem licença).
  static const int proTrialDays = 7;
  /// Plano Grátis: até esta quantidade de entregas na mesma rota (planilha ou manual).
  static const int freeMaxDeliveriesPerRoute = 50;
  static bool withinFreeRouteLimit(int n) => n <= freeMaxDeliveriesPerRoute;
  static String importOverLimitMessage(int n) =>
      'Plano Grátis: até $freeMaxDeliveriesPerRoute entregas por rota (sua planilha tem $n). '
      'Trial PRO e licença PRO importam sem esse limite. '
      'Em Mais, confira se aparece "Trial PRO" ou "ROTA PRIME PRO".';
  static String manualAddBlockedMessage(int n) =>
      'Plano Grátis: até $freeMaxDeliveriesPerRoute entregas por rota (você já tem $n). '
      'Inicie outra rota ou ative PRO para continuar.';
}
