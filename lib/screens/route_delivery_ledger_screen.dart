import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/utils/parada_labels.dart';

/// Lista de entregues, não entregues e pendentes — desfazer só aqui, com confirmação.
class RouteDeliveryLedgerScreen extends ConsumerStatefulWidget {
  const RouteDeliveryLedgerScreen({super.key, this.onOpenOnMap});

  final void Function(Parada parada)? onOpenOnMap;

  @override
  ConsumerState<RouteDeliveryLedgerScreen> createState() =>
      _RouteDeliveryLedgerScreenState();
}

class _RouteDeliveryLedgerScreenState extends ConsumerState<RouteDeliveryLedgerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _confirmRevert(Parada p) async {
    final label = p.entregue ? 'entrega' : 'marcação de falha';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        title: const Text('Desfazer status?', style: TextStyle(color: Colors.white)),
        content: Text(
          'A parada voltará para pendente. Confirme que deseja desfazer esta $label.',
          style: const TextStyle(color: Colors.white70, height: 1.35),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, desfazer', style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(rotaProvider.notifier).revertParadaDelivery(p.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status da parada restaurado para pendente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paradas = ref.watch(rotaProvider).paradas;
    final delivered = paradas.where((p) => p.entregue).toList()
      ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
    final failed = paradas.where((p) => p.falha && !p.entregue).toList()
      ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
    final pending = paradas.where((p) => !p.entregue && !p.falha).toList()
      ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        title: const Text('Entregas da rota'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.orange,
          labelColor: AppColors.orange,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Entregues (${delivered.length})'),
            Tab(text: 'Não deu (${failed.length})'),
            Tab(text: 'Pendentes (${pending.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ParadaLedgerList(
            paradas: delivered,
            allParadas: paradas,
            emptyMessage: 'Nenhuma entrega registrada ainda.',
            status: _LedgerStatus.delivered,
            onRevert: _confirmRevert,
            onOpenOnMap: widget.onOpenOnMap,
          ),
          _ParadaLedgerList(
            paradas: failed,
            allParadas: paradas,
            emptyMessage: 'Nenhuma parada marcada como não entregue.',
            status: _LedgerStatus.failed,
            onRevert: _confirmRevert,
            onOpenOnMap: widget.onOpenOnMap,
          ),
          _ParadaLedgerList(
            paradas: pending,
            allParadas: paradas,
            emptyMessage: 'Todas as paradas foram finalizadas.',
            status: _LedgerStatus.pending,
            onRevert: null,
            onOpenOnMap: widget.onOpenOnMap,
          ),
        ],
      ),
    );
  }
}

enum _LedgerStatus { delivered, failed, pending }

class _ParadaLedgerList extends StatelessWidget {
  const _ParadaLedgerList({
    required this.paradas,
    required this.allParadas,
    required this.emptyMessage,
    required this.status,
    required this.onRevert,
    required this.onOpenOnMap,
  });

  final List<Parada> paradas;
  final List<Parada> allParadas;
  final String emptyMessage;
  final _LedgerStatus status;
  final Future<void> Function(Parada)? onRevert;
  final void Function(Parada)? onOpenOnMap;

  @override
  Widget build(BuildContext context) {
    if (paradas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 15),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: paradas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = paradas[i];
        final pin = ParadaLabels.packageOrderDisplay(p);
        final refLine = ParadaLabels.deliveryReferenceLine(p);
        Color accent;
        IconData statusIcon;
        switch (status) {
          case _LedgerStatus.delivered:
            accent = AppColors.successGreen;
            statusIcon = Icons.check_rounded;
          case _LedgerStatus.failed:
            accent = AppColors.stopFailed;
            statusIcon = Icons.close_rounded;
          case _LedgerStatus.pending:
            accent = AppColors.orange;
            statusIcon = Icons.schedule_rounded;
        }

        return Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onOpenOnMap != null ? () => onOpenOnMap!(p) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      pin,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(statusIcon, size: 16, color: accent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                refLine,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.destinationAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                        if (p.spxTn.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              p.spxTn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onRevert != null)
                    TextButton(
                      onPressed: () => onRevert!(p),
                      style: TextButton.styleFrom(foregroundColor: AppColors.orange),
                      child: const Text('Desfazer'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
