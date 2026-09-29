import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

enum RouteMapPanelMode { map, list }

/// Setas + ícone de mapa no centro (sem abas largas).
class RouteMapModeToggle extends StatelessWidget {
  const RouteMapModeToggle({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  final RouteMapPanelMode mode;
  final ValueChanged<RouteMapPanelMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sheet,
      elevation: 8,
      shadowColor: Colors.black54,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ModeArrow(
              icon: Icons.keyboard_arrow_up_rounded,
              enabled: mode == RouteMapPanelMode.map,
              onTap: () => onModeChanged(RouteMapPanelMode.map),
              tooltip: 'Modo mapa',
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.map_outlined,
              size: 26,
              color: mode == RouteMapPanelMode.map
                  ? AppColors.orange
                  : Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 16),
            _ModeArrow(
              icon: Icons.keyboard_arrow_down_rounded,
              enabled: mode == RouteMapPanelMode.list,
              onTap: () => onModeChanged(RouteMapPanelMode.list),
              tooltip: 'Modo lista',
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeArrow extends StatelessWidget {
  const _ModeArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? AppColors.orange.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.06),
        shape: CircleBorder(
          side: BorderSide(
            color: enabled ? AppColors.orange : Colors.white.withValues(alpha: 0.18),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 28,
              color: enabled ? AppColors.orange : Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
