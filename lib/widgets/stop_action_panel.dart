import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/utils/parada_packages.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';
import 'package:rota_prime/widgets/carrier_pin_badge.dart';
import 'package:rota_prime/widgets/circuit_stop_ui.dart';
import 'package:rota_prime/widgets/prazo_entrega_highlight.dart';

/// Endereços visíveis no mapa (sem abrir GPS externo).
class StopRouteAddressPeek {
  const StopRouteAddressPeek({
    required this.currentPinLabel,
    required this.currentAddress,
    this.currentMeta,
    this.nextPinLabel,
    this.nextAddress,
    this.nextMeta,
    this.packageOrders = const [],
    this.currentParada,
    this.multiPackageCaption,
  });

  final String currentPinLabel;
  final String currentAddress;
  final String? currentMeta;
  final String? nextPinLabel;
  final String? nextAddress;
  final String? nextMeta;
  final List<String> packageOrders;
  final Parada? currentParada;
  final String? multiPackageCaption;

  static String? _metaLine(Parada p) {
    final parts = <String>[];
    final b = p.bairro.trim();
    final c = p.city.trim();
    if (b.isNotEmpty) parts.add(b);
    if (c.isNotEmpty) parts.add(c);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static StopRouteAddressPeek fromParadas(
    List<Parada> all,
    Parada current, {
    Parada? next,
  }) {
    final nextLabel = next != null ? ParadaLabels.mapPinLabel(all, next) : null;
    return StopRouteAddressPeek(
      currentPinLabel: ParadaLabels.mapPinLabel(all, current),
      currentAddress: current.destinationAddress.trim().isNotEmpty
          ? current.destinationAddress.trim()
          : current.rawLine.trim(),
      currentMeta: _metaLine(current),
      nextPinLabel: nextLabel,
      nextAddress: next != null
          ? (next.destinationAddress.trim().isNotEmpty
              ? next.destinationAddress.trim()
              : next.rawLine.trim())
          : null,
      nextMeta: next != null ? _metaLine(next) : null,
      packageOrders: () {
        final pending = ParadaLabels.pendingPackageOrderLabelsAtStop(all, current);
        if (pending.isNotEmpty) return pending;
        return ParadaLabels.packageOrderLabelsAtStop(all, current);
      }(),
      currentParada: current,
      multiPackageCaption: _multiPackageCaption(all, current),
    );
  }

  static String? _multiPackageCaption(List<Parada> all, Parada current) {
    if (!ParadaLabels.hasMultiplePackagesAtStop(all, current)) return null;
    final atStop = all.where((p) => sameDeliveryStop(p, current)).toList();
    final total = packageUnitsAtAddress(all, current);
    final pending = atStop.where((p) => !p.entregue && !p.falha).toList();
    if (pending.isEmpty) {
      return '$total pacotes neste endereço';
    }
    pending.sort(
      (a, b) => ParadaLabels.packageOrder(a).compareTo(ParadaLabels.packageOrder(b)),
    );
    final labels = pending.map(ParadaLabels.packageOrderDisplay).toList();
    final orders = labels.join(', ');
    final extras = labels.where((l) => l == ParadaLabels.latePackageMarker).length;
    if (extras == labels.length) {
      return extras == 1
          ? '1 pacote $orders (extra na rota)'
          : '$total pacotes · $orders (extras na rota)';
    }
    return '$total pacotes · pend. $orders';
  }
}

/// Atalhos da parada selecionada — layout compacto e legível.
class StopActionPanel extends StatelessWidget {
  const StopActionPanel({
    super.key,
    this.onNavigate,
    required this.onFailed,
    required this.onDelivered,
    this.routePeek,
    this.onPrevious,
    this.onNext,
    this.onUndoLast,
  });

  /// Se omitido, use [routePeek] no mapa (economia de bateria).
  final VoidCallback? onNavigate;
  final VoidCallback onFailed;
  final VoidCallback onDelivered;
  final StopRouteAddressPeek? routePeek;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onUndoLast;

  static const _btnH = 40.0;

  static final _pillShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onUndoLast != null) ...[
          OutlinedButton.icon(
            onPressed: onUndoLast,
            icon: const Icon(Icons.undo_rounded, size: 16, color: AppColors.orange),
            label: const Text(
              'Desfazer última entrega',
              style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.orange),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: _pillShape,
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (routePeek != null && (onPrevious != null || onNext != null))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                _StopNavArrowButton(up: true, onPressed: onPrevious),
                Expanded(
                  child: Text(
                    'Parada ${routePeek!.currentPinLabel}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StopNavArrowButton(up: false, onPressed: onNext),
              ],
            ),
          ),
        if (routePeek != null)
          StopAddressPeekCard(peek: routePeek!)
        else if (onNavigate != null)
          SizedBox(
            width: double.infinity,
            height: _btnH,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation_rounded, size: 20),
              label: const Text(
                'Abrir GPS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.2),
              ),
              style: primaryOrangeButtonStyle().copyWith(
                shape: WidgetStateProperty.all(_pillShape),
                elevation: WidgetStateProperty.all(3),
              ),
            ),
          ),
        if (routePeek == null && (onPrevious != null || onNext != null)) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (onPrevious != null)
                Expanded(
                  child: SizedBox(
                    height: _btnH,
                    child: OutlinedButton.icon(
                      onPressed: onPrevious,
                      icon: const Icon(Icons.skip_previous_rounded, size: 18),
                      label: const Text('Anterior', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                        shape: _pillShape,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    ),
                  ),
                ),
              if (onPrevious != null && onNext != null) const SizedBox(width: 6),
              if (onNext != null)
                Expanded(
                  child: SizedBox(
                    height: _btnH,
                    child: OutlinedButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.skip_next_rounded, size: 18),
                      label: const Text('Próxima', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                        shape: _pillShape,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _btnH,
                child: ElevatedButton.icon(
                  onPressed: onFailed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.stopFailed,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: _pillShape,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Não deu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: _btnH,
                child: ElevatedButton.icon(
                  onPressed: onDelivered,
                  style: successButtonStyle().copyWith(
                    shape: WidgetStateProperty.all(_pillShape),
                    elevation: WidgetStateProperty.all(2),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 6)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Entreguei', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StopAddressPeekCard extends StatelessWidget {
  const StopAddressPeekCard({required this.peek, super.key});

  final StopRouteAddressPeek peek;

  @override
  Widget build(BuildContext context) {
    final hasNext = peek.nextAddress != null &&
        peek.nextAddress!.isNotEmpty &&
        peek.nextPinLabel != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PinBadge(label: peek.currentPinLabel, emphasized: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              peek.currentAddress,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.28,
                              ),
                            ),
                          ),
                          if (peek.currentParada != null) ...[
                            const SizedBox(width: 6),
                            StopDeliveryStatusChip(parada: peek.currentParada!),
                          ],
                        ],
                      ),
                      if (peek.currentMeta != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          peek.currentMeta!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.52),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (peek.packageOrders.isNotEmpty ||
                          peek.multiPackageCaption != null ||
                          (peek.currentParada != null &&
                              RomaneioCarrierBranding.showsDeliveryBadgeForParada(
                                peek.currentParada!,
                              )) ||
                          (peek.currentParada?.prazoEntrega.trim().isNotEmpty ??
                              false)) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (peek.packageOrders.isNotEmpty ||
                                peek.multiPackageCaption != null)
                              PackageOrdersRow(
                                packageOrders: peek.packageOrders,
                                showMultiPackageIcon: peek.packageOrders.length > 1,
                                compact: true,
                                inlineCaption: peek.multiPackageCaption,
                              ),
                            if (peek.currentParada != null &&
                                RomaneioCarrierBranding.showsDeliveryBadgeForParada(
                                  peek.currentParada!,
                                ))
                              CarrierDeliveryBadge(
                                parada: peek.currentParada!,
                                compact: true,
                              ),
                            if (peek.currentParada != null &&
                                peek.currentParada!.prazoEntrega.trim().isNotEmpty)
                              PrazoEntregaHighlight(
                                prazo: peek.currentParada!.prazoEntrega,
                                compact: true,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (hasNext) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PinBadge(label: peek.nextPinLabel!, emphasized: false),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próxima parada',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          peek.nextAddress!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        if (peek.nextMeta != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            peek.nextMeta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StopNavArrowButton extends StatelessWidget {
  const _StopNavArrowButton({required this.up, required this.onPressed});

  final bool up;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled
          ? AppColors.orange.withValues(alpha: 0.22)
          : Colors.white.withValues(alpha: 0.06),
      shape: CircleBorder(
        side: BorderSide(
          color: enabled ? AppColors.orange : Colors.white.withValues(alpha: 0.18),
          width: 2,
        ),
      ),
      elevation: enabled ? 2 : 0,
      shadowColor: AppColors.orange.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            up ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: enabled ? AppColors.orange : Colors.white.withValues(alpha: 0.25),
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge({required this.label, required this.emphasized});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.orange : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: emphasized ? Colors.black : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}
