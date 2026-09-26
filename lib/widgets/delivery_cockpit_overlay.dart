import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/services/delivery_cockpit_service.dart';

/// Tela escurecida: um toque grande acende de novo (simples para qualquer idade).
class DeliveryCockpitOverlay extends StatefulWidget {
  const DeliveryCockpitOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<DeliveryCockpitOverlay> createState() => _DeliveryCockpitOverlayState();
}

class _DeliveryCockpitOverlayState extends State<DeliveryCockpitOverlay> {
  final _cockpit = DeliveryCockpitService.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cockpit.dimListenable,
      builder: (context, _) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _cockpit.bumpAwakeTimer(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (_cockpit.isActive && _cockpit.dimmed)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await _cockpit.wakeForInteraction();
                    },
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.28),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SafeArea(
                          minimum: const EdgeInsets.all(20),
                          child: Material(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 6,
                            child: InkWell(
                              onTap: () async {
                                await _cockpit.wakeForInteraction();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 18,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app, color: Colors.white, size: 28),
                                    SizedBox(width: 12),
                                    Text(
                                      'TOQUE PARA VER O MAPA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
