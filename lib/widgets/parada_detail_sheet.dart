import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/widgets/entrega_undo_snackbar.dart';
import 'package:rota_prime/widgets/spoke_widgets.dart';
import 'package:rota_prime/widgets/manual_parada_dialog.dart';
import 'package:rota_prime/widgets/stop_detail_body.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showParadaDetailSheet(
  BuildContext context,
  WidgetRef ref,
  Parada parada, {
  void Function(Parada next)? onDeliveredAdvance,
  void Function(Parada delivered)? onDeliveredUndo,
  void Function(Parada delivered)? onDeliveredMarked,
  void Function(Parada next)? onSkipToNext,
  VoidCallback? onUndoLast,
}) async {
  final sheetHeight = MediaQuery.sizeOf(context).height * 0.92;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (ctx) {
      return SizedBox(
        height: sheetHeight,
        child: DraggableScrollableSheet(
          expand: true,
          initialChildSize: 0.58,
          minChildSize: 0.28,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0.28, 0.58, 0.92],
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final rotaState = ref.watch(rotaProvider);
                final updated = rotaState.paradas.firstWhere(
                  (p) => p.id == parada.id,
                  orElse: () => parada,
                );
                final mapSettings = ref.watch(mapSettingsProvider);
                final previousInRoute =
                    RotaNotifier.previousInRouteOrder(rotaState.paradas, updated);
                final nextInRoute =
                    RotaNotifier.nextPendingInRouteOrderAfter(rotaState.paradas, updated);

                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.sheet,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      MediaQuery.of(ctx).viewInsets.bottom + 24,
                    ),
                    children: [
                      const SheetDragHandle(),
                      StopDetailBody(
                        parada: updated,
                        totalStops: rotaState.totalPacotes,
                        allParadas: rotaState.paradas,
                        selectedColumns: rotaState.selectedColumns,
                        stopIdDisplay: mapSettings.stopIdDisplay,
                        onClose: () => Navigator.pop(ctx),
                        onEdit: () async {
                          Navigator.pop(ctx);
                          await showEditParadaDialog(context, ref, updated);
                        },
                        onNavigate: () => _navigate(context, updated, mapSettings.navApp),
                        onPrevious: previousInRoute == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                onSkipToNext?.call(previousInRoute);
                              },
                        onNext: nextInRoute == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                onSkipToNext?.call(nextInRoute);
                              },
                        onFailed: () async {
                          await ref.read(rotaProvider.notifier).markEntregue(
                                updated.id,
                                entregue: false,
                                falha: true,
                              );
                        },
                        onUndoLast: onUndoLast,
                        onDelivered: () async {
                          final delivered = updated;
                          final next = await ref.read(rotaProvider.notifier).markEntregue(
                                delivered.id,
                                entregue: true,
                                falha: false,
                              );
                          if (context.mounted) {
                            if (onDeliveredMarked != null) {
                              onDeliveredMarked(delivered);
                            } else {
                              showEntregaUndoSnackBar(
                                context,
                                ref,
                                delivered: delivered,
                                marginBottom: MediaQuery.sizeOf(context).height * 0.2,
                                onUndone: () => onDeliveredUndo?.call(delivered),
                              );
                            }
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (next != null) {
                            onDeliveredAdvance?.call(next);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}

Future<void> _navigate(
  BuildContext context,
  Parada p,
  NavAppPreference pref,
) async {
  if (p.latitude == null || p.longitude == null) return;
  final waze = Uri.parse('waze://?q=${p.latitude},${p.longitude}&navigate=yes');
  final gmaps = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}',
  );

  Future<void> openWaze() async {
    if (await canLaunchUrl(waze)) {
      await launchUrl(waze);
    } else {
      await launchUrl(gmaps, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openGmaps() async {
    await launchUrl(gmaps, mode: LaunchMode.externalApplication);
  }

  NavAppPreference choice = pref;
  if (pref == NavAppPreference.askEachTime) {
    choice = await showModalBottomSheet<NavAppPreference>(
          context: context,
          backgroundColor: AppColors.sheet,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.navigation, color: Colors.white70),
                  title: const Text('Waze', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, NavAppPreference.wazeFirst),
                ),
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.white70),
                  title: const Text('Google Maps', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, NavAppPreference.googleMapsFirst),
                ),
              ],
            ),
          ),
        ) ??
        NavAppPreference.wazeFirst;
  }

  switch (choice) {
    case NavAppPreference.wazeFirst:
      await openWaze();
    case NavAppPreference.googleMapsFirst:
      await openGmaps();
    case NavAppPreference.askEachTime:
      await openWaze();
  }
}
