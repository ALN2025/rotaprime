import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/config/mercadopago_checkout_config.dart';
import 'package:rota_prime/services/mercadopago_checkout_launcher.dart';

/// Assinar PRO mensal — cartão ou Pix (checkout Mercado Pago).
class ProSubscriptionPayButtons extends StatelessWidget {
  const ProSubscriptionPayButtons({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final price = MercadoPagoCheckoutConfig.monthlyPriceBrl.toStringAsFixed(0);
    if (compact) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => openMercadoPagoSubscriptionCheckout(context, pix: false),
              icon: const Icon(Icons.credit_card, size: 18),
              label: Text('Cartão R\$$price/mês'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: AppColors.orange),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => openMercadoPagoSubscriptionCheckout(context, pix: true),
              icon: const Icon(Icons.pix, size: 18),
              label: Text('Pix R\$$price/mês'),
              style: primaryOrangeButtonStyle(),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PRO mensal — R\$$price (cartão ou Pix)',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Use o ID do aparelho (abaixo). O pagamento renova todo mês; se não pagar, o PRO expira sozinho.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => openMercadoPagoSubscriptionCheckout(context, pix: false),
                icon: const Icon(Icons.credit_card, size: 18),
                label: Text('Cartão R\$$price/mês'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orange,
                  side: const BorderSide(color: AppColors.orange),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => openMercadoPagoSubscriptionCheckout(context, pix: true),
                icon: const Icon(Icons.pix, size: 18),
                label: Text('Pix R\$$price/mês'),
                style: primaryOrangeButtonStyle(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
