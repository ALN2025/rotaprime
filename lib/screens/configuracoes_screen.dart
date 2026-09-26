import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rota_prime/widgets/support_whatsapp_button.dart';
import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/providers/map_settings_provider.dart';

import 'package:rota_prime/providers/rota_provider.dart';

import 'package:rota_prime/providers/subscription_provider.dart';

import 'package:rota_prime/screens/compare_plans_screen.dart';

import 'package:rota_prime/screens/file_picker_screen.dart';

import 'package:rota_prime/screens/legal_document_screen.dart';

import 'package:rota_prime/screens/licenses_screen.dart';

import 'package:rota_prime/screens/mapeamento_colunas_screen.dart';

import 'package:rota_prime/widgets/dev_signature_badge.dart';
import 'package:rota_prime/widgets/device_id_settings_tile.dart';

import 'package:rota_prime/widgets/map_layers_sheet.dart';

import 'package:rota_prime/app/app_info.dart';
import 'package:rota_prime/config/plan_limits.dart';
import 'package:rota_prime/widgets/pro_gate.dart';



class ConfiguracoesScreen extends ConsumerStatefulWidget {

  const ConfiguracoesScreen({super.key});



  @override

  ConsumerState<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();

}



class _ConfiguracoesScreenState extends ConsumerState<ConfiguracoesScreen> {

  void _saved(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),

    );

  }

  Future<T?> _pick<T>(

    String title,

    List<(T value, String label)> options,

    T current,

  ) {

    return showModalBottomSheet<T>(

      context: context,

      backgroundColor: AppColors.sheet,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),

      ),

      builder: (ctx) {

        return SafeArea(

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              Padding(

                padding: const EdgeInsets.all(16),

                child: Text(

                  title,

                  style: const TextStyle(

                    color: Colors.white,

                    fontSize: 18,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

              for (final opt in options)

                ListTile(

                  title: Text(opt.$2, style: const TextStyle(color: Colors.white)),

                  trailing: opt.$1 == current

                      ? const Icon(Icons.check, color: AppColors.orange)

                      : null,

                  onTap: () => Navigator.pop(ctx, opt.$1),

                ),

              const SizedBox(height: 8),

            ],

          ),

        );

      },

    );

  }



  Widget _settingsSwitch({

    required bool value,

    required String title,

    required String subtitle,

    required ValueChanged<bool> onChanged,

  }) {

    return SwitchListTile(

      value: value,

      title: Text(title, style: const TextStyle(color: Colors.white)),

      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),

      activeThumbColor: Colors.white,

      activeTrackColor: AppColors.orange,

      inactiveThumbColor: Colors.white70,

      inactiveTrackColor: const Color(0xFF3A3A3A),

      onChanged: onChanged,

    );

  }



  Future<void> _confirmCancelPro() async {

    final ok = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        backgroundColor: AppColors.sheet,

        title: const Text('Cancelar PRO?', style: TextStyle(color: Colors.white)),

        content: const Text(

          'Você voltará ao plano Gratuito. A otimização de rota será desativada. '

          'Suas rotas salvas no aparelho permanecem.',

          style: TextStyle(color: Colors.white70),

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Manter PRO')),

          TextButton(

            onPressed: () => Navigator.pop(ctx, true),

            child: const Text('Voltar ao Gratuito', style: TextStyle(color: Colors.red)),

          ),

        ],

      ),

    );

    if (ok != true || !mounted) return;

    await ref.read(subscriptionProvider.notifier).cancelPro();

    _saved('Plano Gratuito ativado');

  }



  @override

  Widget build(BuildContext context) {

    final settings = ref.watch(mapSettingsProvider);

    final rotaState = ref.watch(rotaProvider);

    final sub = ref.watch(subscriptionProvider);

    final cols = rotaState.selectedColumns;

    final colSummary = cols.isEmpty

        ? 'Padrão (todas visíveis na entrega)'

        : '${cols.length} colunas selecionadas';



    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(

        backgroundColor: AppColors.background,

        foregroundColor: Colors.white,

        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.bold)),

      ),

      body: ListView(

        children: [

          _section('Preferências de rota'),

          ListTile(

            title: const Text('App de navegação', style: TextStyle(color: Colors.white)),

            subtitle: Text(settings.navAppLabel, style: const TextStyle(color: AppColors.muted)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () async {

              final picked = await _pick(

                'App de navegação',

                [

                  (NavAppPreference.wazeFirst, 'Waze (depois Google Maps)'),

                  (NavAppPreference.googleMapsFirst, 'Google Maps (depois Waze)'),

                  (NavAppPreference.askEachTime, 'Perguntar ao navegar'),

                ],

                settings.navApp,

              );

              if (picked != null && mounted) {

                ref.read(mapSettingsProvider.notifier).setNavApp(picked);

                _saved('Navegação: ${ref.read(mapSettingsProvider).navAppLabel}');

              }

            },

          ),

          ListTile(

            title: const Text('Lado da parada', style: TextStyle(color: Colors.white)),

            subtitle: Text(settings.stopSideLabel, style: const TextStyle(color: AppColors.muted)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () async {

              final picked = await _pick(

                'Lado da parada',

                [

                  (StopSidePreference.anySide, 'Qualquer lado do veículo'),

                  (StopSidePreference.leftSide, 'Lado esquerdo'),

                  (StopSidePreference.rightSide, 'Lado direito'),

                ],

                settings.stopSide,

              );

              if (picked != null && mounted) {

                ref.read(mapSettingsProvider.notifier).setStopSide(picked);

                _saved('Lado: ${ref.read(mapSettingsProvider).stopSideLabel}');

              }

            },

          ),

          ListTile(

            title: const Text('Tempo médio na parada', style: TextStyle(color: Colors.white)),

            subtitle: Text('${settings.avgStopMinutes} min', style: const TextStyle(color: AppColors.muted)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () async {

              final picked = await _pick(

                'Tempo na parada',

                [for (var i = 1; i <= 5; i++) (i, '$i min')],

                settings.avgStopMinutes,

              );

              if (picked != null && mounted) {

                ref.read(mapSettingsProvider.notifier).setAvgStopMinutes(picked);

                _saved('Tempo na parada: $picked min');

              }

            },

          ),

          ListTile(

            title: const Text('Tipo de veículo', style: TextStyle(color: Colors.white)),

            subtitle: Text(settings.vehicleTypeLabel, style: const TextStyle(color: AppColors.muted)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () async {

              final picked = await _pick(

                'Tipo de veículo',

                [

                  (VehicleType.car, 'Carro'),

                  (VehicleType.motorcycle, 'Moto'),

                  (VehicleType.truck, 'Caminhão'),

                ],

                settings.vehicleType,

              );

              if (picked != null && mounted) {

                ref.read(mapSettingsProvider.notifier).setVehicleType(picked);

                _saved('Veículo: ${ref.read(mapSettingsProvider).vehicleTypeLabel}');

              }

            },

          ),

          _settingsSwitch(

            value: settings.avoidTolls,

            title: 'Evitar pedágios',

            subtitle: 'Economizar evitando estradas com pedágio',

            onChanged: (v) {

              ref.read(mapSettingsProvider.notifier).setAvoidTolls(v);

              _saved(v ? 'Evitar pedágios: ligado' : 'Evitar pedágios: desligado');

            },

          ),

          ListTile(

            title: const Text('ID de parada', style: TextStyle(color: Colors.white)),

            subtitle: Text(settings.stopIdLabel, style: const TextStyle(color: AppColors.muted)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () async {

              final picked = await _pick(

                'ID de parada',

                [

                  (StopIdDisplay.modernByRoute, 'Moderno e por ordem de rota'),

                  (StopIdDisplay.numericOnly, 'Somente número'),

                ],

                settings.stopIdDisplay,

              );

              if (picked != null && mounted) {

                ref.read(mapSettingsProvider.notifier).setStopIdDisplay(picked);

                _saved('ID: ${ref.read(mapSettingsProvider).stopIdLabel}');

              }

            },

          ),

          _settingsSwitch(

            value: settings.navBubble,

            title: 'Balão do modo de navegação',

            subtitle: 'Veja informações de entrega enquanto navega',

            onChanged: (v) {

              ref.read(mapSettingsProvider.notifier).setNavBubble(v);

              _saved(v ? 'Balão de navegação: ligado' : 'Balão de navegação: desligado');

            },

          ),

          ListTile(

            title: const Text('Tipo de mapa', style: TextStyle(color: Colors.white)),

            subtitle: Text(settings.basemap.label, style: const TextStyle(color: AppColors.muted)),

            trailing: const Icon(Icons.layers_outlined, color: AppColors.orange),

            onTap: () => showMapLayersSheet(context, ref),

          ),

          _section('Preferências gerais'),

          const ListTile(

            title: Text('Tema', style: TextStyle(color: Colors.white)),

            subtitle: Text('Escuro', style: TextStyle(color: AppColors.muted)),

          ),

          _section('Planilha e importação'),

          ListTile(

            title: const Text('Colunas na entrega', style: TextStyle(color: Colors.white)),

            subtitle: Text(colSummary, style: const TextStyle(color: AppColors.muted)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () async {

              await Navigator.of(context).push(

                MaterialPageRoute(

                  builder: (_) => const MapeamentoColunasScreen(saveColumnsOnly: true),

                ),

              );

              if (mounted) setState(() {});

            },

          ),

          ListTile(

            title: const Text('Importar planilha', style: TextStyle(color: Colors.white)),

            subtitle: const Text(

              'XLSX — mapear colunas e criar rota',

              style: TextStyle(color: AppColors.muted),

            ),

            trailing: const Icon(Icons.upload_file, color: AppColors.orange),

            onTap: () {

              Navigator.of(context).push(

                MaterialPageRoute(builder: (_) => const FilePickerScreen()),

              );

            },

          ),

          if (sub.isPro)
            _settingsSwitch(
              value: rotaState.useGpsOrigin,
              title: 'Iniciar rota no GPS',
              subtitle: 'Usar posição atual ao otimizar (PRO)',
              onChanged: (v) {
                ref.read(rotaProvider.notifier).setUseGpsOrigin(v);
                _saved(v ? 'GPS na otimização: ligado' : 'GPS na otimização: desligado');
              },
            )
          else
            const ListTile(
              title: Text('Iniciar rota no GPS', style: TextStyle(color: Colors.white54)),
              subtitle: Text(
                'Recurso PRO — ative a licença para otimizar com GPS',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),

          _section('Assinatura'),

          _subscriptionPlanSpecCard(sub),

          DeviceIdSettingsTile(
            onCopied: () => _saved('ID copiado — envie pelo WhatsApp do suporte para receber a chave'),
          ),

          ListTile(
            title: const Text('Sincronizar plano / trial', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Use depois de liberar trial no suporte (mesmo ID acima). '
              'Desinstalar + reinstalar também consulta a lista online.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            trailing: const Icon(Icons.sync, color: AppColors.orange),
            onTap: () async {
              await ref.read(subscriptionProvider.notifier).reloadPlanFromServer();
              if (!mounted) return;
              final s = ref.read(subscriptionProvider);
              _saved('Plano atualizado: ${s.planLabel}');
            },
          ),

          ListTile(

            title: Text(sub.planLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),

            subtitle: Text(
              sub.planStatusLine,
              style: const TextStyle(color: AppColors.muted),
            ),

            trailing: Icon(
              switch (sub.accessKind) {
                PlanAccessKind.licensedPro => Icons.verified,
                PlanAccessKind.trialPro => Icons.hourglass_top_rounded,
                PlanAccessKind.free => Icons.lock_open_outlined,
              },
              color: switch (sub.accessKind) {
                PlanAccessKind.licensedPro => AppColors.orange,
                PlanAccessKind.trialPro => const Color(0xFF5EEAD4),
                PlanAccessKind.free => Colors.white38,
              },
            ),

            onTap: () => showProActivationDialog(context, ref),

          ),

          ListTile(

            title: const Text('Comparar planos', style: TextStyle(color: Colors.white)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () {

              Navigator.of(context).push(

                MaterialPageRoute(builder: (_) => const ComparePlansScreen()),

              );

            },

          ),

          if (sub.isLicensedPro)

            ListTile(

              title: const Text('Cancelar assinatura', style: TextStyle(color: Colors.red)),

              onTap: _confirmCancelPro,

            ),

          ListTile(

            title: const Text('Licenças', style: TextStyle(color: Colors.white)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () {

              Navigator.of(context).push(

                MaterialPageRoute(builder: (_) => const LicensesScreen()),

              );

            },

          ),

          _section('Suporte'),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SupportWhatsAppButton(
              onOpenFailed: () {
                _saved('Não foi possível abrir o WhatsApp. Verifique se o app está instalado.');
              },
            ),
          ),

          ListTile(

            title: const Text('Termos de uso', style: TextStyle(color: Colors.white)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () {

              Navigator.of(context).push(

                MaterialPageRoute(

                  builder: (_) => const LegalDocumentScreen(kind: LegalDocumentKind.terms),

                ),

              );

            },

          ),

          ListTile(

            title: const Text('Política de privacidade', style: TextStyle(color: Colors.white)),

            trailing: const Icon(Icons.chevron_right, color: Colors.white38),

            onTap: () {

              Navigator.of(context).push(

                MaterialPageRoute(

                  builder: (_) => const LegalDocumentScreen(kind: LegalDocumentKind.privacy),

                ),

              );

            },

          ),

          _section('ROTA PRIME'),

          const DevSignatureBadge(),

          ListTile(

            title: const Text('Versão', style: TextStyle(color: Colors.white)),

            subtitle: Text(AppInfo.fullVersionLabel, style: const TextStyle(color: AppColors.muted)),

          ),

          const SizedBox(height: 24),

        ],

      ),

    );

  }



  Widget _subscriptionPlanSpecCard(SubscriptionState sub) {
    final max = PlanLimits.freeMaxDeliveriesPerRoute;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Especificação dos planos',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                switch (sub.accessKind) {
                  PlanAccessKind.licensedPro => 'Seu plano: PRO (licença neste aparelho)',
                  PlanAccessKind.trialPro =>
                    'Seu plano: Trial PRO (${sub.trialDaysRemaining} dia${sub.trialDaysRemaining == 1 ? '' : 's'} restantes)',
                  PlanAccessKind.free => 'Seu plano: Grátis',
                },
                style: TextStyle(
                  color: sub.isPro ? AppColors.orange : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (sub.isTrialActive) ...[
                const SizedBox(height: 6),
                Text(
                  'Primeiros ${PlanLimits.proTrialDays} dias neste aparelho: todos os recursos PRO. '
                  'Se desinstalar o app durante o trial e instalar de novo, volta ao plano Grátis (trial não reinicia). '
                  'Depois do trial: Grátis (até ${PlanLimits.freeMaxDeliveriesPerRoute} entregas/rota).',
                  style: TextStyle(
                    color: const Color(0xFF5EEAD4).withValues(alpha: 0.85),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
              if (sub.accessKind == PlanAccessKind.free && sub.trialStartedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Trial encerrado neste aparelho (7 dias usados ou app reinstalado). '
                  'Plano Grátis ativo. Para PRO de novo, use a chave de licença.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Grátis — R\$ 0',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 4),
              _planSpecLine(true, 'Planilha XLSX, mapa, pins e ordem do romaneio'),
              _planSpecLine(true, 'Entregue / Não entregue e lista de entregas'),
              _planSpecLine(true, 'Até $max entregas (linhas) por rota importada'),
              _planSpecLine(false, 'Otimização OSRM e linha laranja no mapa'),
              _planSpecLine(false, 'Reotimizar rota e gastos do dia (PRO)'),
              const SizedBox(height: 10),
              const Text(
                'PRO — pagamento único por aparelho',
                style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 4),
              _planSpecLine(true, 'Rotas ilimitadas (sem teto de entregas)'),
              _planSpecLine(true, 'Otimização, trecho laranja GPS→pin, reotimizar'),
              _planSpecLine(true, 'Controle de gastos, CEP+número, GPS na otimização'),
              _planSpecLine(true, 'Licença por aparelho: copie o ID abaixo e envie ao suporte (WhatsApp)'),
              const SizedBox(height: 10),
              Text(
                'Trial: ${PlanLimits.proTrialDays} dias de PRO uma vez por aparelho. '
                'Desinstalar/reinstalar o app → plano Grátis (sem novo trial). '
                'Depois: Grátis (até ${PlanLimits.freeMaxDeliveriesPerRoute} entregas/rota). '
                'Licença paga pode ser revogada online se necessário.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planSpecLine(bool included, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            included ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: included ? AppColors.successGreen : Colors.white38,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: included ? 0.82 : 0.45),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {

    return Padding(

      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),

      child: Text(

        title,

        style: const TextStyle(

          color: AppColors.orange,

          fontWeight: FontWeight.w600,

          fontSize: 13,

        ),

      ),

    );

  }

}


