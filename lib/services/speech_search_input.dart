import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/services/speech_permission.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Ditado curto para **buscar/filtrar** paradas na rota (não adiciona endereço).
Future<String?> listenRouteSearchQuery(BuildContext context) async {
  final mic = await ensureMicrophonePermission();
  if (!mic) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permita o acesso ao microfone para buscar')),
      );
    }
    return null;
  }

  final speech = SpeechToText();
  final ready = await speech.initialize();
  if (!ready) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconhecimento de voz indisponível')),
      );
    }
    return null;
  }

  if (!context.mounted) return null;
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ListenSearchDialog(speech: speech),
  );
  await speech.stop();
  return result?.trim().isEmpty == true ? null : result?.trim();
}

class _ListenSearchDialog extends StatefulWidget {
  const _ListenSearchDialog({required this.speech});

  final SpeechToText speech;

  @override
  State<_ListenSearchDialog> createState() => _ListenSearchDialogState();
}

class _ListenSearchDialogState extends State<_ListenSearchDialog> {
  String _text = '';
  bool _listening = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await widget.speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() => _text = r.recognizedWords);
      },
      localeId: 'pt_BR',
      listenMode: ListenMode.search,
    );
  }

  @override
  void dispose() {
    widget.speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sheet,
      title: const Text('Buscar na rota', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _listening ? 'Fale endereço, código ou bairro…' : _text,
            style: TextStyle(
              color: _text.isEmpty ? Colors.white54 : Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (_listening)
            const LinearProgressIndicator(color: AppColors.orange),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            await widget.speech.stop();
            if (mounted) setState(() => _listening = false);
          },
          child: const Text('Parar'),
        ),
        ElevatedButton(
          onPressed: _text.trim().isEmpty ? null : () => Navigator.pop(context, _text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
          child: const Text('Buscar'),
        ),
      ],
    );
  }
}
