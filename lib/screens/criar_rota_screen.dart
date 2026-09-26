import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/models/rota.dart';
import 'package:rota_prime/providers/rota_provider.dart';

import 'package:rota_prime/utils/rota_titulo.dart';

import 'package:rota_prime/app/app_navigator.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/widgets/add_parada_sheet.dart';
import 'package:rota_prime/widgets/add_stops_sheet.dart';
import 'package:rota_prime/services/spreadsheet_picker.dart';



class CriarRotaScreen extends ConsumerStatefulWidget {

  const CriarRotaScreen({super.key});



  @override

  ConsumerState<CriarRotaScreen> createState() => _CriarRotaScreenState();

}



class _CriarRotaScreenState extends ConsumerState<CriarRotaScreen> {

  late final TextEditingController _nomeCtrl;

  int _dateChoice = 0;

  bool _reuseStops = false;

  DateTime? _customPickedDate;



  @override

  void initState() {

    super.initState();

    _nomeCtrl = TextEditingController(text: defaultWeekdayRouteLabel(DateTime.now()));

  }



  @override

  void dispose() {

    _nomeCtrl.dispose();

    super.dispose();

  }



  String _formatDay(DateTime d) {

    const weekdays = ['seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.', 'dom.'];

    const months = [

      'jan.',

      'fev.',

      'mar.',

      'abr.',

      'mai.',

      'jun.',

      'jul.',

      'ago.',

      'set.',

      'out.',

      'nov.',

      'dez.',

    ];

    return '${weekdays[d.weekday - 1]} ${d.day} de ${months[d.month - 1]}';

  }



  Future<void> _prepareDraftRota() async {
    final notifier = ref.read(rotaProvider.notifier);
    notifier.setPendingRouteCreation(
      scheduledAt: _scheduledDateTime(),
      label: _nomeCtrl.text.trim(),
    );
    final st = ref.read(rotaProvider);
    if (st.rotaId != null && st.rota?.status == RotaStatus.rascunho) {
      return;
    }
    if (st.rotaId == null) {
      if (await notifier.loadLatestDraft()) {
        if (ref.read(rotaProvider).rota?.status == RotaStatus.rascunho) {
          return;
        }
      }
    }
    notifier.clearWorkingRoute(keepCreationMeta: true);
    await notifier.ensureEmptyDraftRota();
  }

  Future<void> _openManualAddParada() async {
    await _prepareDraftRota();
    if (!mounted) return;
    await openManualParadaFlow(context, ref);
    if (mounted) setState(() {});
  }

  Future<void> _finishAndOpenMap() async {
    await _prepareDraftRota();
    if (!mounted) return;
    Navigator.pop(context);
    final ctx = rootAppContext ?? context;
    if (ctx.mounted) navigateToRouteMap(ctx, ref);
  }

  DateTime _scheduledDateTime() {

    final now = DateTime.now();

    final day = switch (_dateChoice) {

      1 => now.add(const Duration(days: 1)),

      2 => _customPickedDate ?? now,

      _ => now,

    };

    return DateTime(day.year, day.month, day.day, now.hour, now.minute);

  }



  @override

  Widget build(BuildContext context) {

    final today = DateTime.now();

    final tomorrow = today.add(const Duration(days: 1));

    final preview = buildRotaTitulo(

      when: _scheduledDateTime(),

      nomeOpcional: _nomeCtrl.text,

    );

    final hasOpenRoute = ref.watch(
      rotaProvider.select((s) => s.rotaId != null && s.paradas.isNotEmpty),
    );



    return Scaffold(

      backgroundColor: AppColors.background,

      body: SafeArea(

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            Padding(

              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),

              child: Row(

                children: [

                  IconButton(

                    onPressed: () => Navigator.pop(context),

                    icon: const Icon(Icons.close, color: Colors.white),

                  ),

                ],

              ),

            ),

            if (hasOpenRoute)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.45)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Você já tem uma rota aberta',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Para somar Magalog, Loggi ou outro PDF, use '
                          '“Adicionar romaneio” — não precisa criar rota nova.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            height: 1.35,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            navigateToRouteMap(context, ref);
                            await pickSpreadsheetAndMergeIntoRoute(ref);
                          },
                          icon: const Icon(Icons.library_add_outlined),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                          ),
                          label: const Text('Adicionar romaneio à rota'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            navigateToRouteMap(context, ref);
                          },
                          child: const Text('Continuar rota no mapa'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const Padding(

              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),

              child: Text(

                'Criar rota',

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 28,

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),

            Padding(

              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),

              child: Text(

                'Será salva como: $preview',

                style: const TextStyle(color: AppColors.orange, fontSize: 13, height: 1.35),

              ),

            ),

            Expanded(

              child: ListView(

                padding: const EdgeInsets.symmetric(horizontal: 20),

                children: [

                  const Text(

                    'Nome da rota (opcional)',

                    style: TextStyle(color: AppColors.muted, fontSize: 14),

                  ),

                  const SizedBox(height: 8),

                  TextField(

                    controller: _nomeCtrl,

                    onChanged: (_) => setState(() {}),

                    style: const TextStyle(color: Colors.white70),

                    decoration: InputDecoration(

                      filled: true,

                      fillColor: AppColors.background,

                      enabledBorder: OutlineInputBorder(

                        borderRadius: BorderRadius.circular(8),

                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),

                      ),

                      focusedBorder: OutlineInputBorder(

                        borderRadius: BorderRadius.circular(8),

                        borderSide: const BorderSide(color: AppColors.orange),

                      ),

                    ),

                  ),

                  const SizedBox(height: 28),

                  const Text(

                    'Selecione a data',

                    style: TextStyle(color: AppColors.muted, fontSize: 14),

                  ),

                  const SizedBox(height: 12),

                  _DateOptionTile(

                    title: 'Hoje',

                    subtitle: _formatDay(today),

                    selected: _dateChoice == 0,

                    showChevron: false,

                    onTap: () => setState(() => _dateChoice = 0),

                  ),

                  const SizedBox(height: 8),

                  _DateOptionTile(

                    title: 'Amanhã',

                    subtitle: _formatDay(tomorrow),

                    selected: _dateChoice == 1,

                    showChevron: false,

                    onTap: () => setState(() => _dateChoice = 1),

                  ),

                  const SizedBox(height: 8),

                  _DateOptionTile(

                    title: 'Escolher data',

                    subtitle: _customPickedDate != null ? _formatDay(_customPickedDate!) : '',

                    selected: _dateChoice == 2,

                    showChevron: true,

                    onTap: () async {

                      final picked = await showDatePicker(

                        context: context,

                        initialDate: _customPickedDate ?? today,

                        firstDate: today.subtract(const Duration(days: 365)),

                        lastDate: today.add(const Duration(days: 365)),

                        builder: (context, child) {

                          return Theme(

                            data: Theme.of(context).copyWith(

                              colorScheme: const ColorScheme.dark(

                                primary: AppColors.orange,

                                surface: AppColors.sheet,

                              ),

                            ),

                            child: child!,

                          );

                        },

                      );

                      if (picked != null) {

                        setState(() {

                          _customPickedDate = picked;

                          _dateChoice = 2;

                        });

                      }

                    },

                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Adicionar paradas manualmente',
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _openManualAddParada,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.mic, color: AppColors.orange.withValues(alpha: 0.9)),
                            const SizedBox(width: 8),
                            Icon(Icons.edit_location_alt, color: AppColors.orange.withValues(alpha: 0.9)),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Microfone ou digitar endereço',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white38),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque acima para falar no microfone ou escrever endereço, número, ordem ou código do pacote.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, height: 1.35),
                  ),

                  const SizedBox(height: 28),

                  const Text(

                    'Opções de início rápido',

                    style: TextStyle(color: AppColors.muted, fontSize: 14),

                  ),

                  const SizedBox(height: 12),

                  Material(

                    color: AppColors.background,

                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(8),

                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),

                    ),

                    child: CheckboxListTile(

                      value: _reuseStops,

                      onChanged: (v) => setState(() => _reuseStops = v ?? false),

                      activeColor: AppColors.orange,

                      checkColor: Colors.white,

                      secondary: const Icon(Icons.route, color: Colors.white54),

                      title: const Text(

                        'Reutilizar paradas anteriores',

                        style: TextStyle(color: Colors.white, fontSize: 15),

                      ),

                      controlAffinity: ListTileControlAffinity.trailing,

                    ),

                  ),

                ],

              ),

            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Importe o 1º PDF ou planilha. Depois você pode somar Magalog, Loggi e outros na mesma rota.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: OutlinedButton(
                onPressed: () async {
                  await _prepareDraftRota();
                  if (!context.mounted) return;
                  final ctx = rootAppContext ?? context;
                  Navigator.pop(context);
                  if (ctx.mounted) {
                    showAddStopsSheet(ctx, ref);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Importar 1º romaneio'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: _finishAndOpenMap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Abrir mapa da rota',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          ],

        ),

      ),

    );

  }

}



class _DateOptionTile extends StatelessWidget {

  const _DateOptionTile({

    required this.title,

    required this.subtitle,

    required this.selected,

    required this.showChevron,

    required this.onTap,

  });



  final String title;

  final String subtitle;

  final bool selected;

  final bool showChevron;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return Material(

      color: AppColors.background,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(8),

        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),

      ),

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(8),

        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

          child: Row(

            children: [

              const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 22),

              const SizedBox(width: 12),

              Expanded(

                child: subtitle.isEmpty

                    ? Text(title, style: const TextStyle(color: Colors.white, fontSize: 16))

                    : RichText(

                        text: TextSpan(

                          style: const TextStyle(fontSize: 16),

                          children: [

                            TextSpan(

                              text: title,

                              style: const TextStyle(

                                color: Colors.white,

                                fontWeight: FontWeight.w600,

                              ),

                            ),

                            TextSpan(

                              text: ' $subtitle',

                              style: const TextStyle(color: Colors.white70),

                            ),

                          ],

                        ),

                      ),

              ),

              if (showChevron)

                const Icon(Icons.chevron_right, color: Colors.white38)

              else

                Icon(

                  selected ? Icons.radio_button_checked : Icons.radio_button_off,

                  color: selected ? AppColors.orange : Colors.white38,

                ),

            ],

          ),

        ),

      ),

    );

  }

}

