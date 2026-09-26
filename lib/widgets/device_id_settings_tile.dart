import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/services/device_id_service.dart';

class DeviceIdSettingsTile extends StatefulWidget {
  const DeviceIdSettingsTile({super.key, this.onCopied});

  final VoidCallback? onCopied;

  @override
  State<DeviceIdSettingsTile> createState() => _DeviceIdSettingsTileState();
}

class _DeviceIdSettingsTileState extends State<DeviceIdSettingsTile> {
  String? _id;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await DeviceIdService.hardwareId();
    if (!mounted) return;
    setState(() {
      _id = id;
      _loading = false;
    });
  }

  Future<void> _copy() async {
    final id = _id;
    if (id == null) return;
    await Clipboard.setData(ClipboardData(text: id));
    widget.onCopied?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phonelink_lock_outlined, color: AppColors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ID único deste aparelho',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cada celular tem um ID próprio e estável. '
                          'A chave PRO só funciona no ID para o qual foi gerada — '
                          'não ativa em outro aparelho.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Desinstalar e instalar de novo no mesmo celular costuma manter o mesmo ID; '
                          'outro telefone ou reset de fábrica exige nova licença com o ID novo.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ListTile(
          title: const Text('ID do aparelho', style: TextStyle(color: Colors.white)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _loading ? 'Carregando…' : (_id ?? '—'),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              if (!_loading && _id != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Copie o ID e envie pelo WhatsApp (Suporte, em Configurações). '
                  'O suporte envia a chave PRO vinculada a este aparelho — cole em «Ativar PRO».',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.copy, color: AppColors.orange),
            onPressed: _loading ? null : _copy,
            tooltip: 'Copiar ID',
          ),
        ),
      ],
    );
  }
}
