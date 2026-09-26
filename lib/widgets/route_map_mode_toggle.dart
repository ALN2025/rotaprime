import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

enum RouteMapPanelMode { map, list }

/// Alternância Modo mapa / Modo lista — fixa acima do dock de ações.
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeChip(
                      label: 'Modo mapa',
                      icon: Icons.map_outlined,
                      selected: mode == RouteMapPanelMode.map,
                      onTap: () => onModeChanged(RouteMapPanelMode.map),
                    ),
                  ),
                  Expanded(
                    child: _ModeChip(
                      label: 'Modo lista',
                      icon: Icons.view_list_rounded,
                      selected: mode == RouteMapPanelMode.list,
                      onTap: () => onModeChanged(RouteMapPanelMode.list),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: selected ? AppColors.orange : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
