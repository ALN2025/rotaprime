import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/screens/conta_rotas_screen.dart';

import 'package:rota_prime/screens/criar_rota_screen.dart';

import 'package:rota_prime/widgets/add_parada_sheet.dart';
import 'package:rota_prime/widgets/add_stops_sheet.dart';
import 'package:rota_prime/providers/app_shell_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';

import 'package:rota_prime/widgets/empty_stops_illustration.dart';

import 'package:rota_prime/widgets/route_map.dart';

import 'package:rota_prime/widgets/driver_route_top_bar.dart';
import 'package:rota_prime/widgets/circuit_view_toggle.dart';
import 'package:rota_prime/widgets/spoke_widgets.dart';



class HomeMapScreen extends ConsumerWidget {

  const HomeMapScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;



  void _openCriarRota(BuildContext context) {

    Navigator.of(context).push(

      MaterialPageRoute(builder: (_) => const CriarRotaScreen()),

    );

  }



  void _openAddStops(BuildContext context, WidgetRef ref) {
    showAddStopsSheet(context, ref);
  }

  Future<void> _startManualRoute(BuildContext context, WidgetRef ref) async {
    await openManualParadaFlow(context, ref, prepareNewRoute: true);
    if (ref.read(rotaProvider).paradas.isEmpty) return;
    if (!context.mounted) return;
    navigateToRouteMap(context, ref);
  }



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final stack = Stack(

        children: [

          const Positioned.fill(

            child: RouteMap(paradas: [], routePoints: []),

          ),

          SafeArea(
            bottom: false,
            child: DriverRouteTopBar(
              view: CircuitDeliveryView.map,
              onViewChanged: (_) {},
              onMenu: () {
                if (embeddedInShell) {
                  switchAppShellTab(ref, 3);
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContaRotasScreen()),
                );
              },
              packagesDone: 0,
              packagesTotal: 0,
              routeActive: false,
              showViewToggle: false,
              showStatCards: false,
              showPlanBadge: embeddedInShell,
            ),
          ),

          Positioned(

            right: 12,

            bottom: 300,

            child: Column(

              children: [

                MapCircleButton(icon: Icons.layers_outlined, onTap: () {}),

                const SizedBox(height: 8),

                MapCircleButton(icon: Icons.my_location, onTap: () {}),

              ],

            ),

          ),

          DraggableScrollableSheet(

            initialChildSize: 0.36,

            minChildSize: 0.26,

            maxChildSize: 0.52,

            builder: (context, controller) {

              return Container(

                decoration: BoxDecoration(

                  color: AppColors.sheet,

                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],

                ),

                child: ListView(

                  controller: controller,

                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),

                  children: [

                    const SheetDragHandle(),

                    Row(

                      mainAxisAlignment: MainAxisAlignment.end,

                      children: [

                        IconButton(

                          onPressed: () => _openAddStops(context, ref),

                          icon: const Icon(Icons.search, color: Colors.white70),

                        ),

                        IconButton(

                          onPressed: () => _openCriarRota(context),

                          icon: const Icon(Icons.more_vert, color: Colors.white70),

                        ),

                      ],

                    ),

                    const SizedBox(height: 8),

                    Material(

                      color: Colors.transparent,

                      child: InkWell(

                        onTap: () => _openCriarRota(context),

                        borderRadius: BorderRadius.circular(12),

                        child: Column(

                          children: [

                            const EmptyStopsIllustration(),

                            const SizedBox(height: 10),

                            Text(

                              'Adicione paradas ou importe a planilha para montar a rota',

                              textAlign: TextAlign.center,

                              style: TextStyle(

                                color: Colors.white.withValues(alpha: 0.55),

                                fontSize: 13,

                                height: 1.35,

                              ),

                            ),

                          ],

                        ),

                      ),

                    ),

                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      onPressed: () => _startManualRoute(context, ref),
                      icon: const Icon(Icons.mic_none, size: 22),
                      label: const Text('Rota manual — microfone ou digitar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(

                      onPressed: () => _openCriarRota(context),

                      icon: const Icon(Icons.add, size: 22),

                      label: const Text('Adicionar paradas / planilha'),

                      style: ElevatedButton.styleFrom(

                        backgroundColor: AppColors.orange,

                        foregroundColor: Colors.white,

                        padding: const EdgeInsets.symmetric(vertical: 12),

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(12),

                        ),

                      ),

                    ),

                    const SizedBox(height: 12),

                    OutlinedButton(

                      onPressed: () => _openAddStops(context, ref),

                      style: OutlinedButton.styleFrom(

                        foregroundColor: AppColors.orange,

                        side: const BorderSide(color: AppColors.orange, width: 1.5),

                        padding: const EdgeInsets.symmetric(vertical: 12),

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(12),

                        ),

                      ),

                      child: const Text('Ler · Importar · Pesquisar'),

                    ),

                  ],

                ),

              );

            },

          ),

        ],

      );

    if (embeddedInShell) {
      return ColoredBox(color: AppColors.background, child: stack);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: stack,
    );

  }

}

