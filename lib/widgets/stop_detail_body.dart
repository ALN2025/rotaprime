import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/utils/delivery_field_visibility.dart';
import 'package:rota_prime/utils/parada_labels.dart';
import 'package:rota_prime/utils/romaneio_carrier_branding.dart';
import 'package:rota_prime/widgets/carrier_pin_badge.dart';
import 'package:rota_prime/widgets/circuit_stop_ui.dart';
import 'package:rota_prime/widgets/prazo_entrega_highlight.dart';
import 'package:rota_prime/widgets/stop_action_panel.dart';

class StopDetailBody extends StatelessWidget {
  const StopDetailBody({
    super.key,
    required this.parada,
    required this.totalStops,
    required this.selectedColumns,
    required this.stopIdDisplay,
    this.onNavigate,
    this.onNext,
    this.onPrevious,
    required this.onFailed,
    required this.onDelivered,
    this.onUndoLast,
    this.showTitle = true,
    this.onClose,
    this.onEdit,
    this.compactActionLabels = false,
    this.allParadas = const [],
    this.emphasizedStopHeader = false,
    this.hideActionBar = false,
    this.actionsBeforeDetails = false,
    this.hideMetaHeader = false,
    this.headerOnly = false,
    this.omitAddressAndPackageTiles = false,
  });

  final Parada parada;
  final int totalStops;
  final List<Parada> allParadas;
  final Set<String> selectedColumns;
  final StopIdDisplay stopIdDisplay;
  final VoidCallback? onNavigate;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback onFailed;
  final VoidCallback onDelivered;
  final VoidCallback? onUndoLast;
  final bool showTitle;
  final VoidCallback? onClose;
  final VoidCallback? onEdit;
  final bool compactActionLabels;
  final bool emphasizedStopHeader;
  final bool hideActionBar;
  /// Entrega ativa: botões antes dos detalhes (sempre visíveis ao rolar).
  final bool actionsBeforeDetails;
  final bool hideMetaHeader;
  final bool headerOnly;
  /// Evita repetir endereço/quantidade já mostrados no cabeçalho da entrega.
  final bool omitAddressAndPackageTiles;

  String get _idLabel => ParadaLabels.idLine(parada, stopIdDisplay);

  String get _locationLine {
    final parts = <String>[
      if (parada.bairro.isNotEmpty) parada.bairro,
      if (parada.city.isNotEmpty) parada.city,
    ];
    return parts.join(', ');
  }

  String get _displayAddress {
    if (parada.destinationAddress.trim().isNotEmpty) return parada.destinationAddress.trim();
    if (parada.rawLine.trim().isNotEmpty) return parada.rawLine.trim();
    return 'Endereço não informado na planilha';
  }

  bool _show(String field) => DeliveryFieldVisibility.show(selectedColumns, field);

  Widget? _headerMenuRow() {
    if (onClose == null && onEdit == null) return null;
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            PopupMenuButton<String>(
              tooltip: 'Mais opções',
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              color: AppColors.card,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_location_alt_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Editar endereço'),
                    ],
                  ),
                ),
                if (onNavigate != null)
                  const PopupMenuItem(
                    value: 'nav',
                    child: Row(
                      children: [
                        Icon(Icons.navigation_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Abrir GPS externo'),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'edit') onEdit!();
                if (value == 'nav') onNavigate?.call();
              },
            ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white70),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _actionBar() {
    return StopActionPanel(
      onNavigate: onNavigate,
      onPrevious: onPrevious,
      onNext: onNext,
      onFailed: onFailed,
      onDelivered: onDelivered,
      onUndoLast: onUndoLast,
    );
  }

  Widget? _multiPackageHighlightTile() {
    final count = ParadaLabels.packageCountAtStop(allParadas, parada);
    if (count <= 1) return null;
    final orders = ParadaLabels.packageOrderLabelsAtStop(allParadas, parada);
    final ordersText = orders.isNotEmpty ? orders.join(', ') : null;
    return CircuitDetailTile(
      icon: Icons.inventory_2_outlined,
      title: '$count pacotes nesta parada',
      subtitle: ordersText != null ? 'Ordens na sacola: $ordersText' : null,
    );
  }

  List<Widget> _detailTiles() {
    final tiles = <Widget>[];
    final hideAddressTile = omitAddressAndPackageTiles || emphasizedStopHeader;

    if (!emphasizedStopHeader &&
        RomaneioCarrierBranding.showsDeliveryBadgeForParada(parada)) {
      tiles.add(CarrierDeliveryBadge(parada: parada, compact: true));
      tiles.add(const SizedBox(height: 8));
    }

    if (!emphasizedStopHeader && parada.prazoEntrega.trim().isNotEmpty) {
      tiles.add(PrazoEntregaHighlight(prazo: parada.prazoEntrega, compact: true));
      tiles.add(const SizedBox(height: 8));
    }

    if (emphasizedStopHeader) {
      final count = ParadaLabels.packageCountAtStop(allParadas, parada);
      final ordersInHeader = _show(DeliveryFieldVisibility.sequence) ||
          _show(DeliveryFieldVisibility.packageQty);
      if (count > 1 && !ordersInHeader) {
        final pkgTile = _multiPackageHighlightTile();
        if (pkgTile != null) tiles.add(pkgTile);
      }
    }

    if (!hideAddressTile && _show(DeliveryFieldVisibility.address)) {
      tiles.add(
        CircuitDetailTile(
          icon: Icons.description_outlined,
          title: _displayAddress,
          subtitle: _locationLine.isNotEmpty ? _locationLine : null,
        ),
      );
    }

    if (_show(DeliveryFieldVisibility.spxTn) && parada.spxTn.isNotEmpty) {
      tiles.add(
        CircuitDetailTile(
          icon: Icons.qr_code_2,
          title: parada.spxTn,
          subtitle: RomaneioCarrierBranding.deliveryCodeHint(
            RomaneioCarrierBranding.carrierOf(parada),
          ),
        ),
      );
    }

    if (_show(DeliveryFieldVisibility.sequence)) {
      if (parada.sequence > 0) {
        tiles.add(
          CircuitDetailTile(
            icon: Icons.format_list_numbered,
            title: 'Sequência ${parada.sequence}',
            subtitle: 'Ordem do pacote na rota',
          ),
        );
      } else if (ParadaLabels.isLateAddedPackage(parada)) {
        tiles.add(
          CircuitDetailTile(
            icon: Icons.new_releases_outlined,
            title: 'Ordem ${ParadaLabels.latePackageMarker}',
            subtitle: ParadaLabels.latePackageHint(parada),
          ),
        );
      }
    }

    if (_show(DeliveryFieldVisibility.stop) && parada.stop > 0) {
      tiles.add(
        CircuitDetailTile(
          icon: Icons.place_outlined,
          title: 'Parada ${parada.stop}',
          subtitle: 'Agrupamento de entrega',
        ),
      );
    }

    if (!omitAddressAndPackageTiles &&
        !emphasizedStopHeader &&
        _show(DeliveryFieldVisibility.packageQty)) {
      tiles.add(
        CircuitDetailTile(
          icon: Icons.inventory_2_outlined,
          title: ParadaLabels.packageQtyLine(allParadas, parada),
        ),
      );
    }

    if (_show(DeliveryFieldVisibility.zipcode) && parada.zipcode.isNotEmpty) {
      tiles.add(
        CircuitDetailTile(
          icon: Icons.markunread_mailbox_outlined,
          title: parada.zipcode,
          subtitle: 'CEP',
        ),
      );
    }

    if (_show(DeliveryFieldVisibility.bairro) && parada.bairro.isNotEmpty) {
      tiles.add(
        CircuitDetailTile(
          icon: Icons.location_city_outlined,
          title: parada.bairro,
          subtitle: 'Bairro',
        ),
      );
    }

    if (_show(DeliveryFieldVisibility.city) && parada.city.isNotEmpty) {
      tiles.add(
        CircuitDetailTile(
          icon: Icons.apartment_outlined,
          title: parada.city,
          subtitle: 'Cidade',
        ),
      );
    }

    if (_show(DeliveryFieldVisibility.atId)) {
      tiles.add(
        CircuitDetailTile(
          icon: Icons.tag_outlined,
          title: _idLabel,
          subtitle: _show(DeliveryFieldVisibility.spxTn) && parada.rawLine.trim().isNotEmpty
              ? parada.rawLine
              : null,
        ),
      );
    }

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    final detailTiles = _detailTiles();
    if (headerOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_headerMenuRow() case final menu?) menu,
          CircuitStopMetaRow(
            parada: parada,
            totalStops: totalStops,
            allParadas: allParadas,
            stopIdDisplay: stopIdDisplay,
            emphasized: emphasizedStopHeader,
            selectedColumns: selectedColumns,
            displayAddress: _displayAddress,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle && !emphasizedStopHeader)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _displayAddress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    height: 1.25,
                  ),
                ),
              ),
              if (onEdit != null)
                PopupMenuButton<String>(
                  tooltip: 'Mais opções',
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: AppColors.card,
                  onSelected: (value) {
                    if (value == 'edit') onEdit!();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_location_alt_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Editar endereço'),
                        ],
                      ),
                    ),
                  ],
                ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        if (showTitle && !emphasizedStopHeader) const SizedBox(height: 10),
        if (!hideMetaHeader) ...[
          CircuitStopMetaRow(
            parada: parada,
            totalStops: totalStops,
            allParadas: allParadas,
            stopIdDisplay: stopIdDisplay,
            emphasized: emphasizedStopHeader,
            selectedColumns: selectedColumns,
            displayAddress: _displayAddress,
          ),
        ],
        if (actionsBeforeDetails && !hideActionBar) ...[
          const SizedBox(height: 14),
          _actionBar(),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < detailTiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          detailTiles[i],
        ],
        if (!actionsBeforeDetails && !hideActionBar) ...[
          const SizedBox(height: 16),
          _actionBar(),
        ],
        if (!emphasizedStopHeader && parada.entregue)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Chip(
              avatar: const Icon(Icons.check_circle, color: Colors.white, size: 18),
              label: const Text('Entregue', style: TextStyle(color: Colors.white)),
              backgroundColor: AppColors.successGreen.withValues(alpha: 0.9),
            ),
          ),
        if (!emphasizedStopHeader && parada.falha)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Chip(
              avatar: const Icon(Icons.cancel, color: Colors.white, size: 18),
              label: const Text('Não entregue', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red.withValues(alpha: 0.9),
            ),
          ),
      ],
    );
  }
}
