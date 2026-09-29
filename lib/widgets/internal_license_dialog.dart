import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/subscription_provider.dart';

/// Ativação por chave (colaboradores) — não aparece na UI pública.
Future<void> showInternalLicenseDialog(BuildContext context, WidgetRef ref) async {
  final ctrl = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppColors.sheet,
        title: const Text('Código interno', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Uso restrito — chave vinculada ao ID deste aparelho.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autocorrect: false,
              maxLines: 4,
              minLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'Código',
                labelStyle: TextStyle(color: Colors.white54),
                alignLabelWithHint: true,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text;
                if (text != null && text.trim().isNotEmpty) {
                  ctrl.text = text.trim();
                }
              },
              icon: const Icon(Icons.content_paste, size: 18),
              label: const Text('Colar'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () async {
              final result =
                  await ref.read(subscriptionProvider.notifier).tryActivateLicense(ctrl.text);
              if (!ctx.mounted) return;
              if (result.ok) {
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PRO ativado neste aparelho')),
                  );
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(result.error ?? 'Código inválido')),
                );
              }
            },
            child: const Text('Ativar'),
          ),
        ],
      );
    },
  );
  ctrl.dispose();
}
