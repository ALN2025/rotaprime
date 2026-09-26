import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/parada_labels.dart';

class DeliveryUndoBanner extends StatelessWidget {
  const DeliveryUndoBanner({
    super.key,
    required this.parada,
    required this.allParadas,
    required this.onUndo,
    this.wasFailure = false,
  });

  final Parada parada;
  final List<Parada> allParadas;
  final VoidCallback onUndo;
  final bool wasFailure;

  @override
  Widget build(BuildContext context) {
    final pin = ParadaLabels.mapPinLabel(allParadas, parada);
    final label = wasFailure ? 'Marcada como não entregue' : 'Entrega registrada';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onUndo,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                wasFailure ? Icons.info_outline : Icons.check_circle_outline,
                color: wasFailure ? Colors.redAccent : AppColors.successGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$label · parada $pin',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: onUndo,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text(
                  'Desfazer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
