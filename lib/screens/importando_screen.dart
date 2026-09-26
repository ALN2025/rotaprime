import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/conta_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/screens/mapeamento_colunas_screen.dart';
import 'package:rota_prime/app/app_navigator.dart';
import 'package:rota_prime/widgets/post_import_romaneio_sheet.dart';

/// Lê a planilha, importa paradas e abre o mapa da rota (sem exigir "Próximo" manual).
class ImportandoScreen extends ConsumerStatefulWidget {
  const ImportandoScreen({super.key});

  @override
  ConsumerState<ImportandoScreen> createState() => _ImportandoScreenState();
}

class _ImportandoScreenState extends ConsumerState<ImportandoScreen> {
  String _status = 'Preparando importação…';
  bool _failed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runImport());
  }

  Future<void> _runImport() async {
    final notifier = ref.read(rotaProvider.notifier);

    final pdf =
        (ref.read(rotaProvider).importFileName ?? '').toLowerCase().endsWith('.pdf');
    setState(() => _status = pdf ? 'Lendo PDF do romaneio…' : 'Lendo planilha…');
    final bytes = await notifier.resolveExcelBytes();
    if (!mounted) return;

    if (bytes == null) {
      _showFail('Planilha não encontrada. Selecione o arquivo .xlsx novamente.');
      return;
    }

    setState(() => _status = pdf
        ? 'Lendo PDF e localizando endereços no mapa (pode levar 1–2 min)…'
        : 'Lendo planilha e montando a rota…');
    try {
      await ref.read(subscriptionProvider.notifier).load();
      if (!mounted) return;
      final sub = ref.read(subscriptionProvider);
      if (sub.isPro) {
        setState(() => _status = '${sub.planLabel}: importando planilha completa…');
      }
      await notifier.importFromMapping();
      ref.invalidate(contaRotasProvider);
      if (!mounted) return;
      final imported = ref.read(rotaProvider);
      if (imported.paradas.isEmpty) {
        _showFail('Nenhuma parada encontrada na planilha.');
        return;
      }
      final nPkg = imported.rota?.pacotesImportados ?? imported.totalPacotes;
      final nStop = imported.rota?.paradasImportadas ?? imported.totalParadas;
      final merge = ref.read(rotaProvider).statusMessage;
      final label = merge.contains('Rota atualizada')
          ? merge
          : (nPkg == nStop
              ? '$nPkg pacotes importados (contagem exata do romaneio)'
              : '$nPkg pacotes · $nStop paradas — contagem exata');
      setState(() => _status = label);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      final sheetCtx = rootAppContext ?? context;
      if (!sheetCtx.mounted) return;
      await showPostImportRomaneioSheet(
        context: sheetCtx,
        ref: ref,
        summary: label,
        isAdditionalRomaneio: merge.contains('Rota atualizada'),
      );
    } catch (e) {
      final msg = e is StateError ? e.message : e.toString();
      _showFail(msg);
    }
  }

  void _showFail(String message) {
    setState(() {
      _failed = true;
      _error = message;
      _status = 'Falha na importação';
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(rotaProvider.select((s) => s.statusMessage));

    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton(
                alignment: Alignment.centerLeft,
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(flex: 2),
              Text(
                _failed ? 'Não foi possível criar a rota' : 'Importando seu arquivo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                live.isNotEmpty ? live : _status,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.92), height: 1.4),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              if (!_failed)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              const Spacer(flex: 3),
              if (_failed) ...[
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MapeamentoColunasScreen(),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Ajustar colunas e tentar de novo'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Voltar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
