import 'package:flutter/material.dart';
import 'package:rota_prime/app/support_contact.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre WhatsApp de suporte (número não é exibido na UI).
Future<bool> openSupportWhatsApp({String? prefilledMessage}) async {
  final uri = SupportContact.whatsAppUri(
    prefilledMessage:
        prefilledMessage ?? 'Olá, preciso de suporte no ROTA PRIME.',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class SupportWhatsAppButton extends StatefulWidget {
  const SupportWhatsAppButton({
    super.key,
    this.compact = false,
    this.onOpenFailed,
  });

  final bool compact;
  final VoidCallback? onOpenFailed;

  @override
  State<SupportWhatsAppButton> createState() => _SupportWhatsAppButtonState();
}

class _SupportWhatsAppButtonState extends State<SupportWhatsAppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    final ok = await openSupportWhatsApp();
    if (!ok && mounted) widget.onOpenFailed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.compact ? 48.0 : 54.0;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.25 + _pulse.value * 0.35;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withValues(alpha: glow),
                blurRadius: 14 + _pulse.value * 10,
                spreadRadius: _pulse.value * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: const Color(0xFF25D366),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _tap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: SizedBox(
            height: h,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: widget.compact ? 22 : 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'Suporte',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: widget.compact ? 15 : 17,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
