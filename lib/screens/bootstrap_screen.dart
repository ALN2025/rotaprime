import 'dart:async';



import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';



import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:intl/date_symbol_data_local.dart';



import 'package:rota_prime/providers/local_settings_provider.dart';

import 'package:rota_prime/providers/subscription_provider.dart';

import 'package:rota_prime/services/isar_service.dart';



import 'package:rota_prime/providers/rota_provider.dart';

import 'package:rota_prime/navigation/route_shell_navigation.dart';

import 'package:rota_prime/screens/app_shell_screen.dart';

import 'package:rota_prime/widgets/aln_splash_view.dart';



/// Inicia no hub de rotas — splash curta; nunca trava em “Inicializando”.

class BootstrapScreen extends ConsumerStatefulWidget {

  const BootstrapScreen({super.key});



  @override

  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();

}



class _BootstrapScreenState extends ConsumerState<BootstrapScreen> {

  @override

  void initState() {

    super.initState();

    _boot();

  }



  Future<void> _boot() async {

    final started = DateTime.now();



    unawaited(_warmUpInBackground());



    await _waitMinSplash(started, const Duration(milliseconds: 1400));



    if (!mounted) return;

    _openShell();



    unawaited(_resumeRouteAfterShell());

    unawaited(_syncPlanAfterShell());

  }



  /// Trial liberado no GitHub pode aparecer segundos depois (cache + rede).

  Future<void> _syncPlanAfterShell() async {

    await Future<void>.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    try {

      await ref.read(subscriptionProvider.notifier).reloadPlanFromServer().timeout(

            const Duration(seconds: 14),

          );

    } catch (_) {}

  }



  Future<void> _warmUpInBackground() async {

    try {

      await IsarService.instance.timeout(const Duration(seconds: 12));

    } catch (e, st) {

      if (kDebugMode) debugPrint('Boot Isar: $e\n$st');

    }

    try {

      await initializeDateFormatting('pt_BR');

    } catch (_) {}

    try {

      await ref.read(localSettingsProvider).load().timeout(const Duration(seconds: 4));

    } catch (_) {}

    try {

      await ref.read(subscriptionProvider.notifier).load().timeout(const Duration(seconds: 6));

    } catch (_) {}

  }



  Future<void> _waitMinSplash(DateTime started, Duration min) async {

    final elapsed = DateTime.now().difference(started);

    if (elapsed < min) {

      await Future<void>.delayed(min - elapsed);

    }

  }



  void _openShell() {

    Navigator.of(context).pushReplacement(

      PageRouteBuilder<void>(

        pageBuilder: (_, __, ___) => const AppShellScreen(),

        transitionsBuilder: (_, animation, __, child) {

          return FadeTransition(opacity: animation, child: child);

        },

        transitionDuration: const Duration(milliseconds: 320),

      ),

    );

  }



  Future<void> _resumeRouteAfterShell() async {

    try {

      final resumed = await ref

          .read(rotaProvider.notifier)

          .tryResumeActiveRoute()

          .timeout(const Duration(seconds: 6));

      if (resumed && mounted) {

        WidgetsBinding.instance.addPostFrameCallback((_) {

          if (mounted) navigateToRouteMap(context, ref);

        });

      }

    } catch (e, st) {

      if (kDebugMode) debugPrint('Boot resume rota: $e\n$st');

    }

  }



  @override

  Widget build(BuildContext context) {

    return const Scaffold(

      backgroundColor: Color(0xFF0A0A0A),

      body: AlnSplashView(),

    );

  }

}

