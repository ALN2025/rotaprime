import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/utils/qr_carrier_infer.dart';
import 'package:rota_prime/utils/qr_parada_fields.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';

/// Nome, endereço e código de conferência (ordem Shopee / nº Magalog / ID Loggi).
Future<bool> showQrScanAddressSheet(
  BuildContext context,
  WidgetRef ref, {
  required int paradaId,
  required String trackingCode,
  String initialName = '',
  String initialAddress = '',
  String initialBagOrder = '',
  String initialDeliveryRef = '',
}) async {
  final route = ref.read(rotaProvider).paradas;
  final carrier = QrCarrierInfer.resolve(
    trackingCode: trackingCode,
    routeParadas: route,
  );
  final isShopee = carrier == RomaneioCarrier.shopee;
  final isMagalogLoggi =
      carrier == RomaneioCarrier.magalog || carrier == RomaneioCarrier.loggi;

  final nameCtrl = TextEditingController(text: initialName);
  final addrCtrl = TextEditingController(text: initialAddress);
  final bagCtrl = TextEditingController(text: initialBagOrder);
  final deliveryCtrl = TextEditingController(
    text: initialDeliveryRef.isNotEmpty ? initialDeliveryRef : trackingCode,
  );
  var saved = false;

  final refLabel = RomaneioCarrierBranding.deliveryCodeHint(carrier);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A1A),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              RomaneioCarrierBranding.displayName(carrier),
              style: TextStyle(
                color: RomaneioCarrierBranding.accent(carrier),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pacote $trackingCode',
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isShopee
                  ? 'Pin no mapa = ordem da rota. No ícone pacote use a ordem da sacola (+N) para conferir.'
                  : 'Endereço no mapa + $refLabel no ícone pacote (como no romaneio).',
              style: const TextStyle(color: Colors.white70, height: 1.35, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (isShopee)
              TextField(
                controller: bagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ordem na sacola (ex.: 47 ou +2)',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.text,
              ),
            if (isMagalogLoggi) ...[
              TextField(
                controller: deliveryCtrl,
                decoration: InputDecoration(
                  labelText: refLabel,
                  labelStyle: const TextStyle(color: Colors.white54),
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do destinatário (opcional)',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addrCtrl,
              autofocus: initialAddress.isEmpty,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Endereço completo',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: primaryOrangeButtonStyle(),
              onPressed: () async {
                final addr = addrCtrl.text.trim();
                if (addr.length < 8) return;
                final ok = await ref.read(rotaProvider.notifier).updateQrParadaDetails(
                      paradaId: paradaId,
                      trackingCode: trackingCode,
                      recipientName: nameCtrl.text.trim(),
                      address: addr,
                      bagOrder: bagCtrl.text.trim(),
                      deliveryRef: deliveryCtrl.text.trim(),
                    );
                if (!ctx.mounted) return;
                if (ok != null) {
                  saved = true;
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Salvar e ir ao mapa'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Depois'),
            ),
          ],
        ),
      );
    },
  );

  nameCtrl.dispose();
  addrCtrl.dispose();
  bagCtrl.dispose();
  deliveryCtrl.dispose();
  return saved;
}

Future<void> showEditQrParadaSheet(
  BuildContext context,
  WidgetRef ref,
  int paradaId,
) async {
  final p = ref.read(rotaProvider.notifier).paradaById(paradaId);
  if (p == null) return;
  final fields = QrParadaFields.parse(p);
  final bag = p.packageOrderLabel.trim().isNotEmpty
      ? p.packageOrderLabel.trim()
      : (p.sequence > 0 ? '${p.sequence}' : '');
  await showQrScanAddressSheet(
    context,
    ref,
    paradaId: paradaId,
    trackingCode: fields.code.isNotEmpty ? fields.code : p.spxTn,
    initialName: fields.recipientName,
    initialAddress: fields.address,
    initialBagOrder: bag,
    initialDeliveryRef: p.spxTn,
  );
}
