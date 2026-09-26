import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/widgets/support_whatsapp_button.dart';

/// Exibe aviso quando o PRO foi revogado remotamente (ex.: reembolso, mau uso).
class LicenseRevokedNoticeListener extends ConsumerStatefulWidget {
  const LicenseRevokedNoticeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LicenseRevokedNoticeListener> createState() =>
      _LicenseRevokedNoticeListenerState();
}

class _LicenseRevokedNoticeListenerState extends ConsumerState<LicenseRevokedNoticeListener> {
  var _shownThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  void _maybeShow() {
    if (!mounted || _shownThisSession) return;
    final pending = ref.read(subscriptionProvider).pendingRevokedNotice;
    if (pending) _openDialog();
  }

  void _openDialog() {
    if (!mounted || _shownThisSession) return;
    _shownThisSession = true;
    showLicenseRevokedDialog(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SubscriptionState>(subscriptionProvider, (prev, next) {
      if (next.pendingRevokedNotice && prev?.pendingRevokedNotice != true) {
        _openDialog();
      }
    });
    return widget.child;
  }
}

Future<void> showLicenseRevokedDialog(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.sheet,
      title: const Text(
        'Licença PRO revogada',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'O PRO deste aparelho foi desativado (lista oficial de revogação). '
            'Você continua no plano Grátis.',
            style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
          ),
          SizedBox(height: 12),
          Text(
            'Se acha que é um engano — por exemplo após reembolso já resolvido — '
            'fale com o suporte pelo WhatsApp.',
            style: TextStyle(color: Colors.white54, height: 1.35, fontSize: 13),
          ),
          SizedBox(height: 16),
          SupportWhatsAppButton(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(subscriptionProvider.notifier).acknowledgeRevokedNotice();
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Entendi', style: TextStyle(color: AppColors.orange)),
        ),
      ],
    ),
  );
}
