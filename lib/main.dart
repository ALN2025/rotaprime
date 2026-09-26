import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rota_prime/app/app_navigator.dart';
import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/providers/local_settings_provider.dart';

import 'package:rota_prime/providers/map_settings_provider.dart';

import 'package:rota_prime/providers/rota_provider.dart';

import 'package:rota_prime/screens/bootstrap_screen.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 80;
  imageCache.maximumSizeBytes = 48 << 20;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: RotaPrimeApp()));

}



class RotaPrimeApp extends ConsumerWidget {

  const RotaPrimeApp({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    ref.listen(mapSettingsProvider, (_, _) {

      ref.read(localSettingsProvider).save();

    });

    ref.listen(

      rotaProvider.select((s) => '${s.selectedColumns.join('|')}_${s.useGpsOrigin}'),

      (_, _) {

        ref.read(localSettingsProvider).save();

      },

    );



    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'ROTA PRIME',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: const BootstrapScreen(),
    );

  }

}

