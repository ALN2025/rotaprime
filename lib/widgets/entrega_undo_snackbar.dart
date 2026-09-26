import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/providers/rota_provider.dart';

void showEntregaUndoSnackBar(
  BuildContext context,
  WidgetRef ref, {
  required Parada delivered,
  VoidCallback? onUndone,
  double? marginBottom,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: const Text('Marcou entregue sem querer?'),
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      margin: marginBottom != null
          ? EdgeInsets.only(bottom: marginBottom, left: 16, right: 16)
          : const EdgeInsets.symmetric(horizontal: 16),
      action: SnackBarAction(
        label: 'Desfazer',
        textColor: AppColors.orange,
        onPressed: () => _undoEntrega(ref, delivered, onUndone),
      ),
      duration: const Duration(seconds: 10),
    ),
  );
}

Future<void> _undoEntrega(
  WidgetRef ref,
  Parada delivered,
  VoidCallback? onUndone,
) async {
  await ref.read(rotaProvider.notifier).markEntregue(
        delivered.id,
        entregue: false,
        falha: false,
      );
  onUndone?.call();
}

/// Faixa visível acima do painel (mais fácil de ver que só o SnackBar).
class EntregaUndoBanner extends StatelessWidget {
  const EntregaUndoBanner({
    super.key,
    required this.delivered,
    required this.onUndo,
    required this.onDismiss,
  });

  final Parada delivered;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Parada ${delivered.ordemExibicao} entregue',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: onUndo,
              style: TextButton.styleFrom(foregroundColor: AppColors.orange),
              child: const Text('DESFAZER'),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: Colors.white38, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
