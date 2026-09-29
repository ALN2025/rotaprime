import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

/// Linha de info densa (sem espaçamentos grandes).
class StopInfoRowCompact extends StatelessWidget {
  const StopInfoRowCompact({
    super.key,
    required this.icon,
    required this.text,
    this.subtitle,
  });

  final IconData icon;
  final String text;
  final String? subtitle;

  static const _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  static const _subStyle = TextStyle(
    color: AppColors.muted,
    fontSize: 11,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 28,
      leading: Icon(icon, size: 18, color: Colors.white54),
      title: Text(text, style: _labelStyle, maxLines: 3, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null || subtitle!.trim().isEmpty
          ? null
          : Text(subtitle!, style: _subStyle),
    );
  }
}

class StopParadaActionRow extends StatelessWidget {
  const StopParadaActionRow({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Colors.white.withValues(alpha: 0.92);
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 28,
      enabled: onTap != null,
      onTap: onTap,
      leading: Icon(icon, size: 20, color: fg),
      title: Text(
        text,
        style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Editar / duplicar / remover — layout da print (compacto).
class StopParadaManageActions extends StatelessWidget {
  const StopParadaManageActions({
    super.key,
    required this.onEdit,
    this.onDuplicate,
    this.onRemove,
  });

  final VoidCallback onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        const Divider(height: 1, color: Colors.white12),
        StopParadaActionRow(
          icon: Icons.edit_outlined,
          text: 'Editar parada',
          onTap: onEdit,
        ),
        if (onDuplicate != null)
          StopParadaActionRow(
            icon: Icons.copy,
            text: 'Duplicar parada',
            onTap: onDuplicate,
          ),
        if (onRemove != null)
          StopParadaActionRow(
            icon: Icons.delete_outline,
            text: 'Remover parada',
            color: Colors.redAccent,
            onTap: onRemove,
          ),
      ],
    );
  }
}
