import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/app_shell_provider.dart';
import 'package:rota_prime/screens/compare_plans_screen.dart';
import 'package:rota_prime/screens/configuracoes_screen.dart';
import 'package:rota_prime/screens/criar_rota_screen.dart';
import 'package:rota_prime/screens/file_picker_screen.dart';
import 'package:rota_prime/screens/controle_gastos_screen.dart';
import 'package:rota_prime/screens/historico_screen.dart';
import 'package:rota_prime/widgets/app_shell_bootstrap.dart';

/// Aba **Mais** — atalhos e configurações.
class MaisTabScreen extends ConsumerWidget {
  const MaisTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const AppShellTitleRow(
              title: 'Mais',
              subtitle: 'Configurações, planos e ferramentas',
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.settings_outlined,
              title: 'Configurações',
              subtitle: 'Mapa, GPS, licença PRO, ID do aparelho',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
              ),
            ),
            _tile(
              context,
              icon: Icons.workspace_premium_outlined,
              title: 'Comparar planos',
              subtitle: 'Grátis x PRO',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ComparePlansScreen()),
              ),
            ),
            _tile(
              context,
              icon: Icons.upload_file_outlined,
              title: 'Importar planilha',
              subtitle: 'Romaneio XLSX',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FilePickerScreen()),
              ),
            ),
            _tile(
              context,
              icon: Icons.add_road_outlined,
              title: 'Criar rota',
              subtitle: 'Planilha ou paradas manuais',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CriarRotaScreen()),
              ),
            ),
            _tile(
              context,
              icon: Icons.history,
              title: 'Histórico de rotas',
              subtitle: 'Busca por dia, extrato e relatório mensal',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoricoScreen()),
              ),
            ),
            _tile(
              context,
              icon: Icons.payments_outlined,
              title: 'Gastos do dia',
              subtitle: 'Combustível, pedágio e despesas da rota (PRO)',
              onTap: () => openControleGastosPro(context, ref),
            ),
            _tile(
              context,
              icon: Icons.map_outlined,
              title: 'Mapa da rota',
              onTap: () => switchAppShellTab(ref, 0),
            ),
            _tile(
              context,
              icon: Icons.folder_open_outlined,
              title: 'Minhas rotas',
              onTap: () => switchAppShellTab(ref, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.orange),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
