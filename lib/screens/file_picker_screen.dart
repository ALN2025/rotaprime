import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/providers/rota_provider.dart';

import 'package:rota_prime/services/spreadsheet_picker.dart';



class FilePickerScreen extends ConsumerWidget {

  const FilePickerScreen({super.key, this.forceNewRoute = false});



  /// Quando true, sempre inicia rota nova (ex.: menu “nova importação”).

  final bool forceNewRoute;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final st = ref.watch(rotaProvider);

    final merging = !forceNewRoute && st.rotaId != null && st.paradas.isNotEmpty;



    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(

        title: Text(

          merging ? 'Adicionar romaneio' : 'Importar romaneio',

          style: const TextStyle(fontWeight: FontWeight.w500),

        ),

      ),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          Text(

            merging

                ? 'Este arquivo será somado à rota que você já tem no mapa '

                    '(Magalog + Loggi + Shopee…). IDs repetidos não entram de novo.'

                : 'Romaneio da sua operação — Shopee, Magalog, Loggi, Mercado Livre… '

                    'Planilha (.xlsx/.csv) ou PDF com texto.\n\n'

                    'Depois do primeiro arquivo você pode adicionar outros romaneios na mesma rota.',

            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), height: 1.45),

          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(

            onPressed: () => pickRomaneioSmart(ref, forceNewRoute: forceNewRoute),

            icon: Icon(merging ? Icons.library_add_outlined : Icons.folder_open),

            style: ElevatedButton.styleFrom(

              backgroundColor: AppColors.orange,

              foregroundColor: Colors.white,

              padding: const EdgeInsets.symmetric(vertical: 18),

            ),

            label: Text(

              merging ? 'Escolher PDF ou planilha' : 'Abrir armazenamento do celular',

              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),

            ),

          ),

          if (merging) ...[

            const SizedBox(height: 16),

            OutlinedButton.icon(

              onPressed: () => pickSpreadsheetAndImport(ref),

              icon: const Icon(Icons.note_add_outlined),

              style: OutlinedButton.styleFrom(

                foregroundColor: Colors.white54,

                side: const BorderSide(color: Colors.white24),

                padding: const EdgeInsets.symmetric(vertical: 14),

              ),

              label: const Text('Começar rota nova em vez disso'),

            ),

          ],

        ],

      ),

    );

  }

}

