import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/utils/delivery_address_core.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';

/// Ao tocar no pin: avisa entregas no mesmo prédio/número (AP, bloco ou nome podem diferir).
Future<void> showSameAddressDeliveriesAlertIfNeeded(
  BuildContext context, {
  required List<Parada> all,
  required Parada tapped,
}) async {
  final group = paradasAtSameBuildingSite(all, tapped);
  if (group.length <= 1) return;

  final n = group.length;
  final packages = ParadaLabels.mapPinPackageOrdersLine(all, tapped);
  final addr = _buildingSiteSummary(tapped);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.sheet,
      icon: const Icon(Icons.apartment_outlined, color: AppColors.orange, size: 32),
      title: Text(
        '$n entregas neste endereço',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Há $n entrega${n == 1 ? '' : 's'} no mesmo endereço (mesma rua e número). '
              'AP, bloco ou destinatário podem ser diferentes — confira todos os pacotes.',
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            if (packages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Pacotes: $packages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (addr.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                addr,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendi', style: TextStyle(color: AppColors.orange)),
        ),
      ],
    ),
  );
}

String _buildingSiteSummary(Parada p) {
  final text = normalizeAddressToken(addressTextForParada(p));
  final street = extractStreetLine(text);
  final number = extractPrimaryStreetNumber(text);
  if (street != null && number != null) {
    return '$street, $number';
  }
  final raw = addressTextForParada(p).trim();
  if (raw.isEmpty) return p.destinationAddress.trim();
  final parts = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
  return parts.take(2).join(', ');
}
