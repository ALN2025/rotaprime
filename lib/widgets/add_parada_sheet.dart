import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rota_prime/app/app_navigator.dart';

import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/models/parada.dart';

import 'package:rota_prime/providers/rota_provider.dart';

import 'package:rota_prime/widgets/manual_parada_dialog.dart';



/// Garante rascunho/rota e abre microfone ou digitar (sem QR).

Future<Parada?> openManualParadaFlow(

  BuildContext context,

  WidgetRef ref, {

  bool prepareNewRoute = false,

}) async {

  final notifier = ref.read(rotaProvider.notifier);

  if (prepareNewRoute) {

    await notifier.prepareNewManualRoute();

  } else if (ref.read(rotaProvider).rotaId == null) {
    final loaded = await notifier.loadLatestDraft();
    if (!loaded) await notifier.ensureEmptyDraftRota();
  }

  final ctx = rootAppContext ?? context;

  if (!ctx.mounted) return null;

  return showAddParadaOptionsSheet(ctx, ref);

}



enum _AddParadaChoice { voice, type }



Future<Parada?> showAddParadaOptionsSheet(BuildContext context, WidgetRef ref) async {

  final choice = await showModalBottomSheet<_AddParadaChoice>(

    context: context,

    isScrollControlled: true,

    backgroundColor: AppColors.sheet,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),

    ),

    builder: (sheetCtx) {

      return SafeArea(

        child: Padding(

          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Container(

                width: 36,

                height: 4,

                decoration: BoxDecoration(

                  color: Colors.white24,

                  borderRadius: BorderRadius.circular(2),

                ),

              ),

              const Padding(

                padding: EdgeInsets.fromLTRB(12, 12, 12, 4),

                child: Align(

                  alignment: Alignment.centerLeft,

                  child: Text(

                    'Como deseja adicionar?',

                    style: TextStyle(

                      color: Colors.white,

                      fontSize: 17,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ),

              ),

              _AddParadaTile(

                icon: Icons.mic,

                title: 'Falar o endereço',

                subtitle: 'Microfone — ditado em português',

                onTap: () => Navigator.pop(sheetCtx, _AddParadaChoice.voice),

              ),

              const Divider(height: 1),

              _AddParadaTile(

                icon: Icons.edit_location_alt_outlined,

                title: 'Digitar endereço',

                subtitle: 'Rua, número, ordem do pacote, código',

                onTap: () => Navigator.pop(sheetCtx, _AddParadaChoice.type),

              ),

            ],

          ),

        ),

      );

    },

  );



  if (!context.mounted || choice == null) return null;



  switch (choice) {

    case _AddParadaChoice.voice:

      return showManualParadaDialog(context, ref, startVoiceInput: true);

    case _AddParadaChoice.type:

      return showManualParadaDialog(context, ref);

  }

}



class _AddParadaTile extends StatelessWidget {

  const _AddParadaTile({

    required this.icon,

    required this.title,

    required this.subtitle,

    required this.onTap,

  });



  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return ListTile(

      onTap: onTap,

      leading: Icon(icon, color: AppColors.orange, size: 28),

      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),

      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),

    );

  }

}


