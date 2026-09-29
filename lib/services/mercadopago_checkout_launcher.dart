import 'package:flutter/material.dart';
import 'package:rota_prime/config/mercadopago_checkout_config.dart';
import 'package:rota_prime/services/device_id_service.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openMercadoPagoSubscriptionCheckout(
  BuildContext context, {
  required bool pix,
}) async {
  final deviceId = (await DeviceIdService.hardwareId()).trim();
  if (deviceId.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível ler o ID do aparelho.')),
      );
    }
    return;
  }

  final url = MercadoPagoCheckoutConfig.checkoutUrl(pix: pix, deviceId: deviceId);
  if (url.contains('COLE_ID_PLANO')) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Links Mercado Pago ainda não configurados no app. Fale com o suporte.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
    return;
  }

  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abra no navegador:\n$url')),
    );
  }
}
