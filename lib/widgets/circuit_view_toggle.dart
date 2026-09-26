import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

enum CircuitDeliveryView { map, list }

/// Alternância Mapa / Lista (estilo Circuit).
class CircuitViewToggle extends StatelessWidget {
  const CircuitViewToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CircuitDeliveryView value;
  final ValueChanged<CircuitDeliveryView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _Chip(
              icon: Icons.map_outlined,
              label: 'Mapa',
              selected: value == CircuitDeliveryView.map,
              onTap: () => onChanged(CircuitDeliveryView.map),
            ),
          ),
          Expanded(
            child: _Chip(
              icon: Icons.format_list_bulleted,
              label: 'Lista',
              selected: value == CircuitDeliveryView.list,
              onTap: () => onChanged(CircuitDeliveryView.list),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orange : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.95),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
