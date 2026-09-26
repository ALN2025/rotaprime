import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/utils/delivery_field_visibility.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/widgets/carrier_pin_badge.dart';
import 'package:rota_prime/widgets/prazo_entrega_highlight.dart';

/// Status da parada — ao lado do pin, nunca por cima do número.
class StopDeliveryStatusChip extends StatelessWidget {
  const StopDeliveryStatusChip({super.key, required this.parada});

  final Parada parada;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    late final IconData icon;
    late final String label;
    late final Border? border;

    if (parada.entregue) {
      background = AppColors.successGreen;
      foreground = Colors.white;
      icon = Icons.check_rounded;
      label = 'Entregue';
      border = null;
    } else if (parada.falha) {
      background = AppColors.stopFailed;
      foreground = Colors.white;
      icon = Icons.close_rounded;
      label = 'Não entregue';
      border = null;
    } else if (ParadaLabels.isLateAddedPackage(parada)) {
      background = Colors.amber.withValues(alpha: 0.22);
      foreground = Colors.amber;
      icon = Icons.add_location_alt_outlined;
      label = 'Adicionado ${ParadaLabels.latePackageMarker}';
      border = Border.all(color: Colors.amber.withValues(alpha: 0.7));
    } else {
      background = AppColors.orange.withValues(alpha: 0.18);
      foreground = AppColors.orange;
      icon = Icons.schedule_rounded;
      label = 'Pendente';
      border = Border.all(color: AppColors.orange.withValues(alpha: 0.65));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmphasizedStopPinBadge extends StatelessWidget {
  const _EmphasizedStopPinBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class CircuitStopMetaRow extends StatelessWidget {
  const CircuitStopMetaRow({
    super.key,
    required this.parada,
    required this.totalStops,
    this.allParadas = const [],
    this.stopIdDisplay = StopIdDisplay.modernByRoute,
    this.timeLabel,
    this.emphasized = false,
    this.selectedColumns = const {},
    this.displayAddress,
  });

  final Parada parada;
  final int totalStops;
  final List<Parada> allParadas;
  final StopIdDisplay stopIdDisplay;
  final String? timeLabel;
  final bool emphasized;
  final Set<String> selectedColumns;
  final String? displayAddress;

  bool _show(String field) => DeliveryFieldVisibility.show(selectedColumns, field);

  @override
  Widget build(BuildContext context) {
    final progress = ParadaLabels.routeAndStopLine(
      allParadas,
      parada,
      totalPackages: totalStops,
    );
    final id = ParadaLabels.idLine(parada, stopIdDisplay);
    final orders = ParadaLabels.packageOrderLabelsAtStop(allParadas, parada);
    var line1 = progress;
    if (timeLabel != null && timeLabel!.isNotEmpty) {
      line1 = '$line1, $timeLabel';
    }

    final pin = ParadaLabels.mapPinLabel(allParadas, parada);
    final address = displayAddress?.trim().isNotEmpty == true
        ? displayAddress!.trim()
        : (parada.destinationAddress.trim().isNotEmpty
            ? parada.destinationAddress.trim()
            : parada.rawLine.trim());
    final locationParts = <String>[
      if (_show(DeliveryFieldVisibility.bairro) && parada.bairro.isNotEmpty) parada.bairro,
      if (_show(DeliveryFieldVisibility.city) && parada.city.isNotEmpty) parada.city,
    ];
    final locationLine = locationParts.join(' · ');
    final showOrders = _show(DeliveryFieldVisibility.sequence) ||
        _show(DeliveryFieldVisibility.packageQty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emphasized)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.sheet,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EmphasizedStopPinBadge(label: pin),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  address.isNotEmpty ? address : 'Endereço não informado',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              StopDeliveryStatusChip(parada: parada),
                            ],
                          ),
                          if (locationLine.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              locationLine,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (_show(DeliveryFieldVisibility.atId) ||
                              _show(DeliveryFieldVisibility.stop) ||
                              line1.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              [
                                if (line1.isNotEmpty) line1,
                                if (_show(DeliveryFieldVisibility.atId)) id,
                                if (_show(DeliveryFieldVisibility.stop) && parada.stop > 0)
                                  'Parada ${parada.stop}',
                              ].where((s) => s.isNotEmpty).join(' · '),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                          if (showOrders && orders.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            PackageOrdersRow(
                              packageOrders: orders,
                              showMultiPackageIcon:
                                  ParadaLabels.hasMultiplePackagesAtStop(allParadas, parada),
                              compact: true,
                            ),
                          ],
                          if (RomaneioCarrierBranding.showsDeliveryBadgeForParada(
                            parada,
                          )) ...[
                            const SizedBox(height: 8),
                            CarrierDeliveryBadge(parada: parada, compact: true),
                          ],
                          if (parada.prazoEntrega.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            PrazoEntregaHighlight(
                              prazo: parada.prazoEntrega,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              StopDeliveryStatusChip(parada: parada),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (line1.isNotEmpty)
                      Text(
                        line1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (_show(DeliveryFieldVisibility.atId))
                      Text(
                        id,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        if (showOrders) ...[
          const SizedBox(height: 8),
          PackageOrdersRow(
            packageOrders: orders,
            showMultiPackageIcon: ParadaLabels.hasMultiplePackagesAtStop(allParadas, parada),
            compact: !emphasized,
          ),
        ],
        if (!emphasized)
          if (ParadaLabels.packageQuantityDescription(allParadas, parada)
              case final qty?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                qty,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
      ],
    );
  }
}

class PackageOrdersRow extends StatelessWidget {
  const PackageOrdersRow({
    super.key,
    required this.packageOrders,
    this.showMultiPackageIcon = false,
    this.compact = false,
    this.inlineCaption,
  });

  final List<String> packageOrders;
  final bool showMultiPackageIcon;
  final bool compact;
  /// Texto curto ao lado dos chips (ex.: vários pacotes no mesmo endereço).
  final String? inlineCaption;

  @override
  Widget build(BuildContext context) {
    if (packageOrders.isEmpty && inlineCaption == null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < packageOrders.length; i++)
          _PackageOrderChip(
            number: packageOrders[i],
            compact: compact,
          ),
        if (showMultiPackageIcon && packageOrders.length == 1)
          Icon(
            Icons.inventory_2,
            size: compact ? 18 : 22,
            color: AppColors.orange.withValues(alpha: 0.85),
          ),
        if (inlineCaption != null && inlineCaption!.trim().isNotEmpty)
          Text(
            inlineCaption!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
      ],
    );
  }
}

class _PackageOrderChip extends StatelessWidget {
  const _PackageOrderChip({
    required this.number,
    this.compact = false,
  });

  final String number;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLate = number == ParadaLabels.latePackageMarker;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: isLate
            ? Colors.amber.withValues(alpha: 0.2)
            : AppColors.orange.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLate
              ? Colors.amber.withValues(alpha: 0.75)
              : AppColors.orange.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: compact ? 16 : 20, color: AppColors.orange),
          const SizedBox(width: 6),
          Text(
            number,
            style: TextStyle(
              color: isLate ? Colors.amber : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: isLate ? (compact ? 12 : 14) : (compact ? 14 : 17),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícone de pacote + número da ordem (Shopee) + quantidade na parada.
class PackageOrderBadge extends StatelessWidget {
  const PackageOrderBadge({
    super.key,
    required this.parada,
    this.allParadas = const [],
    this.compact = false,
  });

  final Parada parada;
  final List<Parada> allParadas;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final orders = ParadaLabels.packageOrderLabelsAtStop(allParadas, parada);
    return PackageOrdersRow(
      packageOrders: orders,
      showMultiPackageIcon: ParadaLabels.hasMultiplePackagesAtStop(allParadas, parada),
      compact: compact,
    );
  }
}

class PackageCountBadge extends StatelessWidget {
  const PackageCountBadge({super.key, required this.count, this.packageOrder});

  final int count;
  final int? packageOrder;

  @override
  Widget build(BuildContext context) {
    final n = count < 1 ? 1 : count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined, size: 18, color: Colors.white.withValues(alpha: 0.85)),
        if (packageOrder != null) ...[
          const SizedBox(width: 4),
          Text(
            '$packageOrder',
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
        const SizedBox(width: 4),
        Text(
          '${n}x',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

typedef CircuitStopAction = void Function();

class CircuitStopActionBar extends StatelessWidget {
  const CircuitStopActionBar({
    super.key,
    required this.onNavigate,
    this.onNext,
    required this.onFailed,
    required this.onDelivered,
    this.onUndoLast,
    this.compactLabels = false,
  });

  final CircuitStopAction onNavigate;
  final CircuitStopAction? onNext;
  final CircuitStopAction onFailed;
  final CircuitStopAction onDelivered;
  final CircuitStopAction? onUndoLast;
  final bool compactLabels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onNavigate,
            icon: const Icon(Icons.navigation, size: 20),
            label: const Text('Abrir GPS'),
            style: primaryOrangeButtonStyle(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _CircuitActionTile(
            label: compactLabels ? 'Próx.' : 'Próxima',
            icon: Icons.skip_next_rounded,
            onTap: onNext,
            enabled: onNext != null,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _CircuitActionTile(
            label: compactLabels ? 'Não' : 'Não entregue',
            icon: Icons.close_rounded,
            style: CircuitActionStyle.danger,
            onTap: onFailed,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CircuitActionTile(
                  label: compactLabels ? 'OK' : 'Entreguei',
                  icon: Icons.check_rounded,
                  style: CircuitActionStyle.success,
                  onTap: onDelivered,
                ),
              ),
              if (onUndoLast != null) ...[
                const SizedBox(width: 4),
                Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onUndoLast,
                    borderRadius: BorderRadius.circular(12),
                    child: Tooltip(
                      message: 'Desfazer última entrega',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.orange,
                          size: compactLabels ? 22 : 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class CircuitDetailTile extends StatelessWidget {
  const CircuitDetailTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: Colors.white54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

enum CircuitActionStyle { muted, danger, success }

class _CircuitActionTile extends StatelessWidget {
  const _CircuitActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.style = CircuitActionStyle.muted,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final CircuitActionStyle style;
  final bool enabled;

  Color get _background {
    switch (style) {
      case CircuitActionStyle.danger:
        return const Color(0xFFD32F2F);
      case CircuitActionStyle.success:
        return AppColors.successGreen;
      case CircuitActionStyle.muted:
        return AppColors.card;
    }
  }

  Color get _iconColor {
    if (iconColor != null) return iconColor!;
    switch (style) {
      case CircuitActionStyle.danger:
      case CircuitActionStyle.success:
        return Colors.white;
      case CircuitActionStyle.muted:
        return Colors.white70;
    }
  }

  Color get _labelColor {
    switch (style) {
      case CircuitActionStyle.danger:
      case CircuitActionStyle.success:
        return Colors.white;
      case CircuitActionStyle.muted:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      borderRadius: BorderRadius.circular(12),
      elevation: style == CircuitActionStyle.muted ? 0 : 2,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _iconColor, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: _labelColor,
                    fontSize: style == CircuitActionStyle.muted ? 9 : 10,
                    fontWeight: style == CircuitActionStyle.muted
                        ? FontWeight.w500
                        : FontWeight.w700,
                    height: 1.1,
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
