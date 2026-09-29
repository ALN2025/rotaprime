import 'package:flutter/material.dart';
import 'package:rota_prime/app/support_messages.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/widgets/support_whatsapp_button.dart';

/// Ajuda, feedback e suporte via WhatsApp (54991376738).
class SupportOverflowMenu extends StatelessWidget {
  const SupportOverflowMenu({super.key, this.iconColor = Colors.white70});

  final Color iconColor;

  Future<void> _open(BuildContext context, String message) async {
    final ok = await openSupportWhatsApp(prefilledMessage: message);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.help_outline, color: iconColor),
      color: AppColors.sheet,
      onSelected: (v) {
        switch (v) {
          case 'help':
            _open(context, SupportMessages.helpAndSupport);
          case 'feedback':
            _open(context, SupportMessages.shareFeedback);
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: 'help',
          child: Text('Ajuda e suporte', style: TextStyle(color: Colors.white)),
        ),
        PopupMenuItem(
          value: 'feedback',
          child: Text('Compartilhar feedback', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
