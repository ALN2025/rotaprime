import 'package:flutter/material.dart';
import 'package:rota_prime/app/app_info.dart';

/// Versão do app no rodapé (barra inferior do shell).
class AppVersionFooter extends StatelessWidget {
  const AppVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Text(
        '${AppInfo.productName} ${AppInfo.fullVersionLabel}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: Colors.white.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}
