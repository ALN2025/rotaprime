import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:rota_prime/app/theme.dart';

/// Envolve o cartão da parada atual com gestos Circuit (swipe entregue / falha).
class CircuitSlidableWrap extends StatelessWidget {
  const CircuitSlidableWrap({
    super.key,
    required this.child,
    required this.onDelivered,
    required this.onFailed,
    this.slidableKey,
  });

  final Widget child;
  final VoidCallback onDelivered;
  final VoidCallback onFailed;
  final Key? slidableKey;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: slidableKey,
      groupTag: 'rota-ativa-stops',
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            onPressed: (_) => onFailed(),
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            icon: Icons.close_rounded,
            label: 'Não entregue',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.36,
        children: [
          SlidableAction(
            onPressed: (_) => onDelivered(),
            backgroundColor: AppColors.successGreen,
            foregroundColor: Colors.white,
            icon: Icons.check_rounded,
            label: 'Entregue',
          ),
        ],
      ),
      child: child,
    );
  }
}
