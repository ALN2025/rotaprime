import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';

import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/models/parada.dart';

import 'package:rota_prime/utils/navigation_parada_utils.dart';

import 'package:rota_prime/utils/pending_parada_groups.dart';

import 'package:rota_prime/utils/route_delivery_stats.dart';

import 'package:rota_prime/widgets/circuit_slidable_stop_row.dart';



/// Lista completa de paradas pendentes — ordem da rota, swipe Circuit.

class CircuitActiveStopList extends StatelessWidget {

  const CircuitActiveStopList({

    super.key,

    required this.paradas,

    required this.activeParadaId,

    required this.driverPosition,

    this.listModeAllDone = false,

    required this.onTapStop,

    required this.onDelivered,

    required this.onFailed,

  });



  final List<Parada> paradas;

  final int? activeParadaId;

  final LatLng? driverPosition;

  final bool listModeAllDone;

  final void Function(Parada p) onTapStop;

  final void Function(Parada p) onDelivered;

  final void Function(Parada p) onFailed;



  List<Parada> _pendingSorted() {

    final list = paradas.where((p) => !p.entregue && !p.falha).toList()

      ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));

    return pendingParadasGroupedByAddress(list);

  }



  List<Parada> _finished() =>

      paradas.where((p) => p.entregue || p.falha).toList();



  @override

  Widget build(BuildContext context) {

    final pending = _pendingSorted();

    final totalPackages = RouteDeliveryStats.totalPackages(paradas);

    if (pending.isEmpty) {

      if (paradas.isEmpty) {

        return Center(

          child: Padding(

            padding: const EdgeInsets.all(32),

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                Icon(

                  Icons.local_shipping_outlined,

                  size: 56,

                  color: Colors.white.withValues(alpha: 0.25),

                ),

                const SizedBox(height: 16),

                Text(

                  'Nenhuma entrega na lista.',

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    color: Colors.white.withValues(alpha: 0.75),

                    fontSize: 17,

                    fontWeight: FontWeight.w700,

                  ),

                ),

                const SizedBox(height: 8),

                Text(

                  'Importe uma planilha no Mapa ou abra uma rota na aba Rotas.',

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    color: Colors.white.withValues(alpha: 0.45),

                    fontSize: 14,

                    height: 1.4,

                  ),

                ),

              ],

            ),

          ),

        );

      }

      return Center(

        child: Padding(

          padding: const EdgeInsets.all(32),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Icon(Icons.check_circle_outline, size: 64, color: AppColors.successGreen.withValues(alpha: 0.9)),

              const SizedBox(height: 16),

              const Text(

                'Rota concluída',

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 22,

                  fontWeight: FontWeight.bold,

                ),

              ),

              const SizedBox(height: 8),

              Text(

                'Todas as ${RouteDeliveryStats.totalStops(paradas)} paradas '

                '(${RouteDeliveryStats.totalPackages(paradas)} pacotes) foram finalizadas.',

                textAlign: TextAlign.center,

                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.4),

              ),

              if (listModeAllDone) ...[

                const SizedBox(height: 12),

                Text(

                  'Use o botão abaixo para encerrar o dia. Depois ela aparece em Rotas.',

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    color: Colors.white.withValues(alpha: 0.5),

                    fontSize: 13,

                    height: 1.35,

                  ),

                ),

              ],

            ],

          ),

        ),

      );

    }



    final nearest = driverPosition != null

        ? pendingParadasByDistance(pending, driverPosition).firstOrNull

        : null;

    final finished = _finished();

    final headerCount = 1;

    final itemCount = headerCount + pending.length + (finished.isEmpty ? 0 : 1 + finished.length);



    return ListView.builder(

      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),

      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),

      itemCount: itemCount,

      itemBuilder: (context, index) {

        if (index == 0) {

          return const Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                'Paradas da rota',

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 18,

                  fontWeight: FontWeight.bold,

                ),

              ),

              SizedBox(height: 4),

              Text(

                'Arraste ← entregue · → não entregue · toque para focar no mapa',

                style: TextStyle(color: Colors.white38, fontSize: 11),

              ),

              SizedBox(height: 12),

            ],

          );

        }



        final pendingIndex = index - headerCount;

        if (pendingIndex < pending.length) {

          final p = pending[pendingIndex];

          final highlight = p.id == activeParadaId ||

              (activeParadaId == null && p.id == nearest?.id) ||

              (activeParadaId != null &&

                  pendingAtSameAddress(paradas, p).any((x) => x.id == activeParadaId));

          return RepaintBoundary(

            child: CircuitSlidableStopRow(

              parada: p,

              allParadas: paradas,

              totalPackages: totalPackages,

              isNextHighlight: highlight,

              onTap: () => onTapStop(p),

              onDelivered: () {

                for (final row in pendingAtSameAddress(paradas, p)) {

                  onDelivered(row);

                }

              },

              onFailed: () => onFailed(p),

            ),

          );

        }



        final finishedStart = headerCount + pending.length;

        if (finished.isEmpty) return const SizedBox.shrink();



        if (index == finishedStart) {

          return const Padding(

            padding: EdgeInsets.only(top: 16, bottom: 8),

            child: Text(

              'Concluídas',

              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),

            ),

          );

        }



        final p = finished[index - finishedStart - 1];

        return Opacity(

          opacity: 0.65,

          child: ListTile(

            dense: true,

            contentPadding: EdgeInsets.zero,

            leading: CircleAvatar(

              radius: 14,

              backgroundColor: p.entregue ? AppColors.successGreen : Colors.red,

              child: Icon(

                p.entregue ? Icons.check : Icons.close,

                size: 16,

                color: Colors.white,

              ),

            ),

            title: Text(

              p.destinationAddress,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(color: Colors.white54, fontSize: 13),

            ),

          ),

        );

      },

    );

  }

}



extension _FirstOrNull<E> on List<E> {

  E? get firstOrNull => isEmpty ? null : first;

}


