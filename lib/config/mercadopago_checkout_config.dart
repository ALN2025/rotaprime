/// Links de checkout Mercado Pago (cartão e Pix recorrente).
///
/// **Não coloque Access Token aqui** — token fica só no Apps Script (webhook).
/// Depois de criar os planos no MP, substitua os templates abaixo ou compile com:
/// `--dart-define=MP_CARD_URL=https://...` e `--dart-define=MP_PIX_URL=https://...`
class MercadoPagoCheckoutConfig {
  MercadoPagoCheckoutConfig._();

  static const double monthlyPriceBrl = 30;

  /// Plano ROTA PRIME R$ 30/mês — link público Mercado Pago + ID do aparelho.
  static const String _rotaPrimeMonthlyCheckout =
      'https://mpago.la/2Gri9DX?external_reference={device_id}';

  static const String _placeholderCard = _rotaPrimeMonthlyCheckout;

  static const String _placeholderPix = _rotaPrimeMonthlyCheckout;

  static const String cardCheckoutUrlTemplate = String.fromEnvironment(
    'MP_CARD_URL',
    defaultValue: _placeholderCard,
  );

  static const String pixCheckoutUrlTemplate = String.fromEnvironment(
    'MP_PIX_URL',
    defaultValue: _placeholderPix,
  );

  static bool get checkoutConfigured {
    return !cardCheckoutUrlTemplate.contains('COLE_ID_PLANO') &&
        !pixCheckoutUrlTemplate.contains('COLE_ID_PLANO') &&
        cardCheckoutUrlTemplate.contains('{device_id}');
  }

  static String checkoutUrl({required bool pix, required String deviceId}) {
    final id = deviceId.trim().toLowerCase();
    final template = pix ? pixCheckoutUrlTemplate : cardCheckoutUrlTemplate;
    return template.replaceAll('{device_id}', Uri.encodeComponent(id));
  }
}
