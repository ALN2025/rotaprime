import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/providers/app_shell_provider.dart';

import 'package:rota_prime/providers/conta_provider.dart';

import 'package:rota_prime/providers/rota_provider.dart';

import 'package:rota_prime/screens/conta_rotas_screen.dart';

import 'package:rota_prime/screens/entregas_tab_screen.dart';

import 'package:rota_prime/screens/home_map_screen.dart';

import 'package:rota_prime/screens/mais_tab_screen.dart';

import 'package:rota_prime/screens/rota_ativa_screen.dart';

import 'package:rota_prime/widgets/app_version_footer.dart';

import 'package:rota_prime/widgets/license_revoked_notice.dart';

import 'package:rota_prime/widgets/app_shell_bootstrap.dart';

import 'package:rota_prime/widgets/plan_policy_auto_sync.dart';



/// Hub principal com rodapé estilo mockup: Mapa · Rotas · Entregas · Mais.

class AppShellScreen extends ConsumerStatefulWidget {

  const AppShellScreen({super.key});



  @override

  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();

}



class _AppShellScreenState extends ConsumerState<AppShellScreen> {

  /// Abas visitadas — evita carregar Rotas/Entregas/Mais no startup (ANR).

  final Set<int> _visitedTabs = {0};

  final Map<int, Widget> _tabBodies = {};



  @override

  void initState() {

    super.initState();

    _tabBodies[0] = const _MapShellTab();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      ref.read(contaRotasProvider.future);

    });

  }



  Widget _bodyForTab(int index) {

    if (!_visitedTabs.contains(index)) {

      return const SizedBox.shrink();

    }

    return _tabBodies.putIfAbsent(index, () {

      switch (index) {

        case 0:

          return const _MapShellTab();

        case 1:

          return AppShellBootstrap(

            body: ContaRotasScreen(embeddedInShell: true),

          );

        case 2:

          return const EntregasTabScreen();

        case 3:

          return const MaisTabScreen();

        default:

          return const SizedBox.shrink();

      }

    });

  }



  @override

  Widget build(BuildContext context) {

    final tab = ref.watch(appShellTabIndexProvider);



    ref.listen<int>(appShellTabIndexProvider, (prev, next) {

      if (!_visitedTabs.contains(next)) {

        setState(() => _visitedTabs.add(next));

      }

    });



    if (!_visitedTabs.contains(tab)) {

      WidgetsBinding.instance.addPostFrameCallback((_) {

        if (mounted && !_visitedTabs.contains(tab)) {

          setState(() => _visitedTabs.add(tab));

        }

      });

    }



    return PlanPolicyAutoSync(

      child: LicenseRevokedNoticeListener(

      child: Scaffold(

        backgroundColor: AppColors.background,

        body: IndexedStack(

          index: tab,

          children: List.generate(4, _bodyForTab),

        ),

        bottomNavigationBar: DecoratedBox(

          decoration: BoxDecoration(

            color: AppColors.sheet,

            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),

            boxShadow: [

              BoxShadow(

                color: Colors.black.withValues(alpha: 0.4),

                blurRadius: 16,

                offset: const Offset(0, -4),

              ),

            ],

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              const AppVersionFooter(),

              NavigationBarTheme(

                data: NavigationBarThemeData(

                  backgroundColor: Colors.transparent,

                  elevation: 0,

                  height: 64,

                  indicatorColor: AppColors.orange.withValues(alpha: 0.22),

                  labelTextStyle: WidgetStateProperty.resolveWith((states) {

                    final selected = states.contains(WidgetState.selected);

                    return TextStyle(

                      fontSize: 12,

                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,

                      color: selected ? AppColors.orange : Colors.white60,

                    );

                  }),

                  iconTheme: WidgetStateProperty.resolveWith((states) {

                    final selected = states.contains(WidgetState.selected);

                    return IconThemeData(

                      color: selected ? AppColors.orange : Colors.white60,

                      size: 24,

                    );

                  }),

                ),

                child: NavigationBar(

                  selectedIndex: tab,

                  onDestinationSelected: (i) => switchAppShellTab(ref, i),

                  destinations: const [

                    NavigationDestination(

                      icon: Icon(Icons.map_outlined),

                      selectedIcon: Icon(Icons.map),

                      label: 'Mapa',

                    ),

                    NavigationDestination(

                      icon: Icon(Icons.route_outlined),

                      selectedIcon: Icon(Icons.route),

                      label: 'Rotas',

                    ),

                    NavigationDestination(

                      icon: Icon(Icons.local_shipping_outlined),

                      selectedIcon: Icon(Icons.local_shipping),

                      label: 'Entregas',

                    ),

                    NavigationDestination(

                      icon: Icon(Icons.grid_view_rounded),

                      selectedIcon: Icon(Icons.grid_view_rounded),

                      label: 'Mais',

                    ),

                  ],

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



class _MapShellTab extends ConsumerStatefulWidget {

  const _MapShellTab();



  @override

  ConsumerState<_MapShellTab> createState() => _MapShellTabState();

}



class _MapShellTabState extends ConsumerState<_MapShellTab>

    with AutomaticKeepAliveClientMixin {

  @override

  bool get wantKeepAlive => true;



  @override

  Widget build(BuildContext context) {

    super.build(context);

    final paradas = ref.watch(rotaProvider.select((s) => s.paradas));

    final rotaKey = ref.watch(
      rotaProvider.select((s) => '${s.rotaId ?? 0}_${s.rota?.status.name ?? 'none'}'),
    );

    return IndexedStack(
      index: paradas.isEmpty ? 0 : 1,
      children: [
        const HomeMapScreen(embeddedInShell: true),
        RotaAtivaScreen(
          key: ValueKey<String>(rotaKey),
          embeddedInShell: true,
        ),
      ],
    );

  }

}


