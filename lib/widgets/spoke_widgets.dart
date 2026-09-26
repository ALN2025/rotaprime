import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({
    super.key,
    this.sheetController,
    this.snapSizes,
    this.minSize = 0.12,
    this.maxSize = 0.88,
    this.expandOnTapSize,
    this.emphasized = false,
    this.peekHint,
    this.openHint,
    this.peekSize,
    this.twoStatePeekOnly = false,
  });

  final DraggableScrollableController? sheetController;
  final List<double>? snapSizes;
  final double minSize;
  final double maxSize;
  /// Fração da tela do painel “aberto” (endereço + botões); usada para esconder textos no mínimo.
  final double? peekSize;
  /// Só abinha ↔ painel (sem patamares altos).
  final bool twoStatePeekOnly;
  /// Ao tocar estando no mínimo, abre neste tamanho (ex.: 0.42).
  final double? expandOnTapSize;
  /// Estilo mais visível (entrega ativa / abbinha do mapa).
  final bool emphasized;
  final String? peekHint;
  final String? openHint;

  void _snapToNearest(DraggableScrollableController controller) {
    if (!controller.isAttached) return;
    var sizes = snapSizes ?? [minSize, 0.38, 0.55, maxSize];
    if (twoStatePeekOnly && sizes.length > 2) {
      final peek = peekSize ?? sizes[1];
      sizes = [minSize, peek];
    }
    final current = controller.size;
    var best = sizes.first;
    var bestDist = (current - best).abs();
    for (final size in sizes) {
      final dist = (current - size).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = size;
      }
    }
    controller.animateTo(
      best,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      width: emphasized ? 52 : 40,
      height: emphasized ? 6 : 5,
      decoration: BoxDecoration(
        color: emphasized ? AppColors.orange.withValues(alpha: 0.85) : Colors.white38,
        borderRadius: BorderRadius.circular(4),
        boxShadow: emphasized
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );

    final controller = sheetController;
    if (controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: bar,
        ),
      );
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final atMin =
            controller.isAttached && controller.size <= minSize + 0.012;
        final deliveryPeek = peekSize ??
            (snapSizes != null && snapSizes!.length > 1 ? snapSizes![1] : 0.28);
        final dragMax = twoStatePeekOnly ? deliveryPeek : maxSize;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            if (!controller.isAttached) return;
            final height = MediaQuery.sizeOf(context).height;
            if (height <= 0) return;
            final next = controller.size - details.delta.dy / height;
            controller.jumpTo(next.clamp(minSize, dragMax));
          },
          onVerticalDragEnd: (_) => _snapToNearest(controller),
          onTap: () {
            if (!controller.isAttached) return;
            final sizes = snapSizes ?? [minSize, 0.42, 0.62, maxSize];
            final current = controller.size;
            final collapsed = current <= minSize + 0.012;
            final openTo =
                expandOnTapSize ?? (sizes.length > 1 ? sizes[1] : 0.42);
            final target = collapsed ? openTo : minSize;
            controller.animateTo(
              target,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            );
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              atMin ? 5 : (emphasized ? 8 : 8),
              16,
              atMin ? 4 : (emphasized ? 6 : 8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emphasized && atMin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      peekHint ?? 'Toque · ver entrega',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                bar,
              ],
            ),
          ),
        );
      },
    );
  }
}

class MapCircleButton extends StatelessWidget {
  const MapCircleButton({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      elevation: 4,
      shadowColor: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Botão principal para montar rota manual: pin + texto laranja (visível no mapa).
class MapAddDeliveryButton extends StatelessWidget {
  const MapAddDeliveryButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Adicionar entrega à rota',
      tooltip: 'Adicionar entrega',
      child: Material(
        color: AppColors.orange,
        elevation: 5,
        shadowColor: AppColors.orange.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.add_location_alt, color: Colors.black, size: 22),
          ),
        ),
      ),
    );
  }
}

class RouteSearchBar extends StatelessWidget {
  const RouteSearchBar({
    super.key,
    this.onScan,
    this.onMic,
    this.onMore,
    this.onChanged,
    this.controller,
  });

  final VoidCallback? onScan;
  final VoidCallback? onMic;
  final VoidCallback? onMore;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Buscar parada na rota',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.search, color: AppColors.orange),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onScan != null)
              IconButton(
                onPressed: onScan,
                icon: const Icon(Icons.document_scanner_outlined, color: AppColors.orange),
              ),
            IconButton(
              onPressed: onMic,
              icon: const Icon(Icons.mic_none, color: AppColors.orange),
            ),
            IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_vert, color: Colors.white54),
            ),
          ],
        ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class RouteConfigTile extends StatelessWidget {
  const RouteConfigTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
  });

  final String title;
  final String subtitle;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(trailingIcon, color: AppColors.orange, size: 20),
          ),
        ],
      ),
    );
  }
}

class RouteTimelineStop extends StatelessWidget {
  const RouteTimelineStop({
    super.key,
    required this.indexLabel,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    this.rawLine,
    this.badge,
    this.isLast = false,
    this.isStart = false,
    this.isPause = false,
    this.showPackageOrderIcon = false,
    this.actions,
  });

  final String indexLabel;
  final String timeLabel;
  final String title;
  final String subtitle;
  final String? rawLine;
  final String? badge;
  final bool isLast;
  final bool isStart;
  final bool isPause;
  final bool showPackageOrderIcon;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                if (isPause)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: Colors.white38,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (isStart)
                  const Icon(Icons.place, color: AppColors.orange, size: 22)
                else
                  Column(
                    children: [
                      if (showPackageOrderIcon)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Icon(Icons.inventory_2_outlined, color: AppColors.orange, size: 16),
                        ),
                      Text(
                        indexLabel,
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.timelineLine.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isPause ? Colors.white70 : Colors.white,
                            fontWeight: isPause ? FontWeight.normal : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (isStart)
                        const Icon(Icons.home_outlined, color: AppColors.orange, size: 22),
                      if (actions != null) actions!,
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                  if (rawLine != null && rawLine!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white38),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rawLine!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OptimizingRouteDialog extends StatefulWidget {
  const OptimizingRouteDialog({
    super.key,
    this.statusMessage,
    this.progress = 0,
  });

  final String? statusMessage;
  final double progress;

  @override
  State<OptimizingRouteDialog> createState() => _OptimizingRouteDialogState();
}

class _OptimizingRouteDialogState extends State<OptimizingRouteDialog>
    with SingleTickerProviderStateMixin {
  static const _logoSize = Size(88, 88);

  late final AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    super.dispose();
  }

  Offset _pinOnTriangle(double t) {
    final w = _logoSize.width;
    final h = _logoSize.height;
    final top = Offset(w * 0.5, h * 0.08);
    final br = Offset(w * 0.92, h * 0.78);
    final bl = Offset(w * 0.08, h * 0.78);
    final seg = (t % 1.0) * 3;
    if (seg < 1) {
      final u = seg;
      return Offset.lerp(top, br, u)!;
    }
    if (seg < 2) {
      final u = seg - 1;
      return Offset.lerp(br, bl, u)!;
    }
    final u = seg - 2;
    return Offset.lerp(bl, top, u)!;
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.progress.clamp(0.0, 1.0);
    return Dialog(
      backgroundColor: const Color(0xFF1E1E26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Montando sua rota',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Em dados móveis pode levar alguns minutos.\nWi‑Fi costuma ser mais rápido.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: _logoSize.width,
              height: _logoSize.height,
              child: AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (context, _) {
                  final pos = _pinOnTriangle(_orbitCtrl.value);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: _logoSize,
                        painter: _PenroseLogoPainter(),
                      ),
                      Positioned(
                        left: pos.dx - 16,
                        top: pos.dy - 28,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.statusMessage?.isNotEmpty == true
                  ? widget.statusMessage!
                  : 'Analisando suas paradas…',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: pct > 0.01 ? pct : null,
                backgroundColor: const Color(0xFF3A3A4A),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
              ),
            ),
            if (pct > 0.01) ...[
              const SizedBox(height: 8),
              Text(
                '${(pct * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PenroseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.08)
      ..lineTo(size.width * 0.92, size.height * 0.78)
      ..lineTo(size.width * 0.08, size.height * 0.78)
      ..close();
    canvas.drawPath(path, paint);
    final inner = Paint()
      ..color = const Color(0xFF1E1E26)
      ..style = PaintingStyle.fill;
    final hole = Path()
      ..moveTo(size.width * 0.5, size.height * 0.28)
      ..lineTo(size.width * 0.72, size.height * 0.68)
      ..lineTo(size.width * 0.28, size.height * 0.68)
      ..close();
    canvas.drawPath(hole, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> showOsrmFailDialog(
  BuildContext context, {
  required VoidCallback onRetry,
  required VoidCallback onSkip,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF1E1E26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Falha ao otimizar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Não deu para terminar agora. Tente de novo com Wi‑Fi ou espere o sinal melhorar. '
              'Você pode usar a ordem da planilha e otimizar depois.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onRetry();
              },
              style: primaryOrangeButtonStyle(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ).copyWith(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              child: const Text('Tentar de novo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onSkip();
              },
              child: const Text('Pular otimização', style: TextStyle(color: AppColors.orange)),
            ),
          ],
        ),
      ),
    ),
  );
}

class XlsxFileIcon extends StatelessWidget {
  const XlsxFileIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: const Text(
        'X',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
