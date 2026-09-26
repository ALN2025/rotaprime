import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/screens/importando_screen.dart';

class MapeamentoColunasScreen extends ConsumerStatefulWidget {
  const MapeamentoColunasScreen({
    super.key,
    this.saveColumnsOnly = false,
    this.addingToExistingRoute = false,
  });

  /// Quando true (vindo de Configurações), só salva colunas sem reimportar rota.
  final bool saveColumnsOnly;
  /// Somando 2º+ romaneio na rota aberta (não cria rota nova).
  final bool addingToExistingRoute;

  @override
  ConsumerState<MapeamentoColunasScreen> createState() =>
      _MapeamentoColunasScreenState();
}

class _MapeamentoColunasScreenState extends ConsumerState<MapeamentoColunasScreen> {
  bool _navigating = false;
  static const _fields = [
    'AT ID',
    'Sequence',
    'Stop',
    'SPX TN',
    'Destination Address',
    'Bairro',
    'City',
    'Zipcode',
    'Package Qty',
  ];

  Map<String, bool> _selected = {};
  List<Map<String, String>> _previewRows = [];
  bool _initStarted = false;
  bool _columnsReady = false;

  void _initSelection() {
    if (_initStarted) return;
    _initStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final bytes = await ref.read(rotaProvider.notifier).resolveExcelBytes();
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione uma planilha XLSX antes de mapear')),
        );
        Navigator.pop(context);
        return;
      }
      try {
        _previewRows =
            await ref.read(rotaProvider.notifier).previewRowsForMapping();
        _applySelectionFromBytes();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ler arquivo: $e')),
        );
        Navigator.pop(context);
        return;
      }
      if (mounted) setState(() => _columnsReady = true);
    });
  }

  void _defaultSelectionMap() {
    _selected = {for (final f in _fields) f: false};
  }

  void _applySelectionFromBytes() {
    final saved = ref.read(rotaProvider).selectedColumns;
    if (saved.isNotEmpty) {
      _selected = {for (final f in _fields) f: saved.contains(f)};
    } else {
      _defaultSelectionMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    _initSelection();
    if (!_columnsReady) {
      return const Scaffold(
        backgroundColor: AppColors.orange,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    final rows = _previewRows;
    final status = ref.watch(rotaProvider).statusMessage;

    final saveOnly = widget.saveColumnsOnly;
    final merging = widget.addingToExistingRoute;

    return Scaffold(
      backgroundColor: AppColors.orange,
      appBar: saveOnly
          ? AppBar(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              title: const Text('Colunas da planilha'),
            )
          : merging
              ? AppBar(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  title: const Text('Adicionar romaneio à rota'),
                )
              : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                saveOnly
                    ? 'Escolha o que aparece ao tocar na entrega (código, bairro, etc.)'
                    : merging
                        ? 'Este arquivo será somado à rota que você já importou. '
                            'Pacotes repetidos (mesmo ID) não entram de novo.'
                        : 'Nada vem marcado — escolha o que quer ver na entrega (código, ordem, bairro…). '
                            'Endereço sempre aparece, mesmo com tudo desmarcado.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final field in _fields)
                    CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _selected[field] ?? false,
                      title: Text(
                        field,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        rows.take(3).map((r) => r[field] ?? '-').join(', '),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => _selected[field] = v ?? false);
                      },
                    ),
                  if (status.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(status, style: const TextStyle(color: Colors.white)),
                    ),
                ],
              ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _navigating ? null : () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _navigating
                          ? null
                          : () async {
                              final chosen = <String>{
                                for (final f in _fields)
                                  if (_selected[f] == true) f,
                              };
                              ref
                                  .read(rotaProvider.notifier)
                                  .applySelectedColumns(chosen);
                              if (saveOnly) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Colunas salvas')),
                                );
                                Navigator.pop(context);
                                return;
                              }
                              setState(() => _navigating = true);
                              if (!context.mounted) return;
                              await Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const ImportandoScreen(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.orange,
                        disabledBackgroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _navigating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.orange,
                              ),
                            )
                          : Text(
                              saveOnly ? 'SALVAR COLUNAS' : 'PRÓXIMO — IMPORTAR PARADAS',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
