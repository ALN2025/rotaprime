import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/providers/subscription_provider.dart';
import 'package:rota_prime/services/speech_permission.dart';
import 'package:rota_prime/services/geocode_service.dart';
import 'package:rota_prime/services/viacep_service.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';
import 'package:rota_prime/utils/manual_address_format.dart';
import 'package:speech_to_text/speech_to_text.dart';

Future<Parada?> showManualParadaDialog(
  BuildContext context,
  WidgetRef ref, {
  String? initialQuery,
  bool startVoiceInput = false,
  Parada? editing,
}) {
  return showDialog<Parada?>(
    context: context,
    builder: (ctx) => _ManualParadaDialog(
      initialQuery: initialQuery,
      startVoiceInput: startVoiceInput,
      editing: editing,
    ),
  );
}

Future<Parada?> showEditParadaDialog(
  BuildContext context,
  WidgetRef ref,
  Parada parada,
) {
  return showManualParadaDialog(context, ref, editing: parada);
}

enum _ManualAddressMode { full, cep }

class _ManualParadaDialog extends ConsumerStatefulWidget {
  const _ManualParadaDialog({
    this.initialQuery,
    this.startVoiceInput = false,
    this.editing,
  });

  final String? initialQuery;
  final bool startVoiceInput;
  final Parada? editing;

  @override
  ConsumerState<_ManualParadaDialog> createState() => _ManualParadaDialogState();
}

class _ManualParadaDialogState extends ConsumerState<_ManualParadaDialog> {
  final _addressCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  final _speech = SpeechToText();
  final _viaCep = ViaCepService();

  _ManualAddressMode _mode = _ManualAddressMode.full;
  ViaCepAddress? _cepData;
  bool _listening = false;
  bool _speechReady = false;
  bool _saving = false;
  bool _loadingCep = false;
  String? _speechError;
  bool? _tipoComercial;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (widget.editing case final p?) {
      final parsed = parseStoredParadaAddress(p);
      _addressCtrl.text = parsed.street;
      _numberCtrl.text = parsed.number;
      _bairroCtrl.text = parsed.neighborhood;
      _cityCtrl.text = parsed.city;
      _complementCtrl.text = parsed.complement ?? '';
      _codeCtrl.text = p.spxTn;
      if (p.sequence > 0) _orderCtrl.text = p.sequence.toString();
      _tipoComercial = p.entregaComercial;
    } else {
      _addressCtrl.text = widget.initialQuery?.trim() ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initSpeech();
      if (widget.startVoiceInput && mounted) {
        setState(() => _mode = _ManualAddressMode.full);
        await _toggleVoice();
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _addressCtrl.dispose();
    _cepCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _bairroCtrl.dispose();
    _cityCtrl.dispose();
    _codeCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  void _refreshTipoFromText(String text) {
    final probe = Parada()..destinationAddress = text;
    setState(() {
      _tipoComercial ??= isBusinessDelivery(probe);
    });
  }

  void _refreshFreeAddressPreview() {
    final preview = _buildAddressForSave(isPro: false);
    if (preview != null) _refreshTipoFromText(preview);
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onError: (e) {
        if (mounted) {
          setState(() {
            _speechError = e.errorMsg;
            _listening = false;
          });
        }
      },
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (mounted) setState(() => _speechReady = ok);
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final mic = await ensureMicrophonePermission();
    if (!mic) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permita o acesso ao microfone')),
        );
      }
      return;
    }
    if (!_speechReady) {
      await _initSpeech();
      if (!_speechReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reconhecimento de voz indisponível neste aparelho')),
          );
        }
        return;
      }
    }
    setState(() {
      _listening = true;
      _speechError = null;
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _addressCtrl.text = result.recognizedWords;
          _refreshTipoFromText(_addressCtrl.text);
        });
      },
      localeId: 'pt_BR',
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> _lookupCep() async {
    setState(() {
      _loadingCep = true;
      _cepData = null;
    });
    final data = await _viaCep.lookup(_cepCtrl.text);
    if (!mounted) return;
    if (data == null || !data.isValid) {
      setState(() => _loadingCep = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP não encontrado. Confira os 8 dígitos.')),
      );
      return;
    }
    setState(() {
      _cepData = data;
      _loadingCep = false;
      _cepCtrl.text = data.formatCep();
    });
    _refreshTipoFromText(data.fullAddress(_numberCtrl.text));
  }

  _ManualAddressMode _effectiveMode(bool isPro) =>
      isPro ? _mode : _ManualAddressMode.full;

  ManualGeocodeInput? _buildGeocodeInput({
    required bool isPro,
    required String address,
  }) {
    final mode = _effectiveMode(isPro);
    if (mode == _ManualAddressMode.cep) {
      final cep = _cepData;
      if (cep == null) return null;
      return ManualGeocodeInput(
        street: cep.logradouro,
        number: _numberCtrl.text.trim(),
        neighborhood: cep.bairro,
        city: cep.localidade,
        stateUf: cep.uf,
        postalCode: cep.cep,
        freeform: address,
      );
    }
    if (!isPro) {
      return ManualGeocodeInput(
        street: _addressCtrl.text.trim(),
        number: _numberCtrl.text.trim(),
        neighborhood: _bairroCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        freeform: address,
      );
    }
    final parsed = parseStoredParadaAddress(Parada()..destinationAddress = address);
    return ManualGeocodeInput(
      street: parsed.street.isNotEmpty ? parsed.street : _addressCtrl.text.trim(),
      number: parsed.number,
      neighborhood: parsed.neighborhood,
      city: parsed.city,
      freeform: address,
    );
  }

  String? _cityHintForGeocode({required bool isPro}) {
    final mode = _effectiveMode(isPro);
    if (mode == _ManualAddressMode.cep && _cepData != null) {
      return '${_cepData!.localidade}/${_cepData!.uf}';
    }
    if (!isPro) {
      final city = _cityCtrl.text.trim();
      return city.isEmpty ? null : city;
    }
    return null;
  }

  String? _buildAddressForSave({required bool isPro}) {
    final mode = _effectiveMode(isPro);
    if (mode == _ManualAddressMode.cep) {
      final cep = _cepData;
      if (cep == null) return null;
      var line = cep.fullAddress(_numberCtrl.text);
      final comp = _complementCtrl.text.trim();
      if (comp.isNotEmpty) {
        line = '$line — $comp';
      }
      return line;
    }
    if (!isPro) {
      final street = _addressCtrl.text.trim();
      final num = _numberCtrl.text.trim();
      final bairro = _bairroCtrl.text.trim();
      final city = _cityCtrl.text.trim();
      if (street.isEmpty || num.isEmpty || bairro.isEmpty || city.isEmpty) {
        return null;
      }
      return buildManualFreeAddress(
        street: street,
        number: num,
        neighborhood: bairro,
        city: city,
        complement: _complementCtrl.text.trim(),
      );
    }
    final a = _addressCtrl.text.trim();
    return a.isEmpty ? null : a;
  }

  Future<void> _submit() async {
    final isPro = ref.read(subscriptionProvider).isPro;
    final mode = _effectiveMode(isPro);
    final address = _buildAddressForSave(isPro: isPro);
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == _ManualAddressMode.cep
                ? 'Informe o CEP (buscar) e o número da casa/apto'
                : !isPro
                    ? 'Preencha rua, número, bairro e cidade'
                    : 'Informe o endereço da parada',
          ),
        ),
      );
      return;
    }
    if (mode == _ManualAddressMode.cep && _cepData == null) {
      await _lookupCep();
      if (_cepData == null) return;
    }
    if (_listening) await _speech.stop();
    setState(() => _saving = true);
    final code = _codeCtrl.text.trim();
    final orderRaw = _orderCtrl.text.trim();
    final orderSeq = int.tryParse(orderRaw);
    final probe = Parada()..destinationAddress = address;
    final comercial = _tipoComercial ?? isBusinessDelivery(probe);
    final neighborhood = !isPro ? _bairroCtrl.text.trim() : _cepData?.bairro;
    final cityHint = _cityHintForGeocode(isPro: isPro);
    final geocodeInput = _buildGeocodeInput(isPro: isPro, address: address);
    try {
      final notifier = ref.read(rotaProvider.notifier);
      final parada = _isEdit
          ? await notifier.updateParadaManual(
              paradaId: widget.editing!.id,
              address: address,
              trackingCode: code.isEmpty ? null : code,
              orderSequence: orderSeq,
              zipcode: mode == _ManualAddressMode.cep ? _cepData?.cep : null,
              entregaComercial: comercial,
              geocodeCityHint: cityHint,
              neighborhood: neighborhood,
              geocodeInput: geocodeInput,
            )
          : await notifier.addParadaManual(
              address: address,
              trackingCode: code.isEmpty ? null : code,
              orderSequence: orderSeq,
              zipcode: mode == _ManualAddressMode.cep ? _cepData?.cep : null,
              entregaComercial: comercial,
              geocodeCityHint: cityHint,
              neighborhood: neighborhood,
              geocodeInput: geocodeInput,
            );
      if (!mounted) return;
      if (parada == null) {
        final detail = ref.read(rotaProvider).statusMessage.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              detail.isNotEmpty
                  ? detail
                  : 'Não foi possível adicionar a parada',
            ),
          ),
        );
        setState(() => _saving = false);
        return;
      }
      Navigator.pop(context, parada);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  Widget _tipoChip() {
    final comercial = _tipoComercial;
    if (comercial == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Tipo:',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
          ChoiceChip(
            label: const Text('Residência'),
            selected: !comercial,
            onSelected: _saving ? null : (_) => setState(() => _tipoComercial = false),
            selectedColor: AppColors.orange.withValues(alpha: 0.35),
            labelStyle: TextStyle(
              color: !comercial ? Colors.white : Colors.white70,
              fontWeight: !comercial ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          ChoiceChip(
            label: const Text('Empresa'),
            selected: comercial,
            onSelected: _saving ? null : (_) => setState(() => _tipoComercial = true),
            selectedColor: AppColors.orange.withValues(alpha: 0.35),
            labelStyle: TextStyle(
              color: comercial ? Colors.white : Colors.white70,
              fontWeight: comercial ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(subscriptionProvider).isPro;
    final mode = isPro ? _mode : _ManualAddressMode.full;

    return AlertDialog(
      backgroundColor: AppColors.sheet,
      title: Text(
        _isEdit ? 'Editar endereço' : 'Adicionar entrega',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPro)
              SegmentedButton<_ManualAddressMode>(
                segments: const [
                  ButtonSegment(
                    value: _ManualAddressMode.cep,
                    label: Text('CEP + nº'),
                    icon: Icon(Icons.markunread_mailbox_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: _ManualAddressMode.full,
                    label: Text('Endereço'),
                    icon: Icon(Icons.edit_location_alt_outlined, size: 18),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _saving
                    ? null
                    : (s) {
                        setState(() {
                          _mode = s.first;
                          _tipoComercial = null;
                        });
                      },
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.white
                        : Colors.white70,
                  ),
                ),
              )
            else
              Text(
                'Rua, número, bairro e cidade — o pin usa a cidade que você informar. CEP é PRO.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
              ),
            const SizedBox(height: 14),
            if (mode == _ManualAddressMode.cep) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cepCtrl,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'CEP',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: '95000-000',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                      onSubmitted: (_) => _lookupCep(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton.filled(
                      tooltip: 'Buscar CEP',
                      onPressed: _saving || _loadingCep ? null : _lookupCep,
                      style: IconButton.styleFrom(backgroundColor: AppColors.orange),
                      icon: _loadingCep
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (_cepData case final c?) ...[
                const SizedBox(height: 8),
                Text(
                  '${c.logradouro}\n${c.bairro} — ${c.localidade}/${c.uf}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), height: 1.35),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _numberCtrl,
                enabled: !_saving,
                keyboardType: TextInputType.text,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Número / apto',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Ex.: 692 ou Apto 202',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
                onChanged: (_) {
                  if (_cepData != null) {
                    _refreshTipoFromText(_cepData!.fullAddress(_numberCtrl.text));
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _complementCtrl,
                enabled: !_saving,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Complemento (opcional)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              _tipoChip(),
            ] else if (isPro) ...[
              TextField(
                controller: _addressCtrl,
                autofocus: !widget.startVoiceInput,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => _refreshTipoFromText(v),
                decoration: InputDecoration(
                  labelText: 'Endereço completo',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Ex.: Rua Exemplo, 123, Bairro',
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixIcon: IconButton(
                    tooltip: _listening ? 'Parar microfone' : 'Falar endereço',
                    onPressed: _saving ? null : _toggleVoice,
                    icon: Icon(
                      _listening ? Icons.mic : Icons.mic_none,
                      color: _listening ? AppColors.orange : Colors.white54,
                    ),
                  ),
                ),
              ),
              if (_listening)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Ouvindo… fale o endereço completo',
                    style: TextStyle(color: AppColors.orange, fontSize: 12),
                  ),
                ),
              if (_speechError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _speechError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              _tipoChip(),
            ] else ...[
              TextField(
                controller: _addressCtrl,
                autofocus: !widget.startVoiceInput,
                maxLines: 1,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => _refreshFreeAddressPreview(),
                decoration: InputDecoration(
                  labelText: 'Nome da rua / logradouro',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Ex.: Rua Romulo Domingos Dal Pozzo',
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixIcon: IconButton(
                    tooltip: _listening ? 'Parar microfone' : 'Falar rua',
                    onPressed: _saving ? null : _toggleVoice,
                    icon: Icon(
                      _listening ? Icons.mic : Icons.mic_none,
                      color: _listening ? AppColors.orange : Colors.white54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _numberCtrl,
                enabled: !_saving,
                keyboardType: TextInputType.text,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => _refreshFreeAddressPreview(),
                decoration: const InputDecoration(
                  labelText: 'Número',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Ex.: 720 ou Apto 202',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bairroCtrl,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => _refreshFreeAddressPreview(),
                decoration: const InputDecoration(
                  labelText: 'Bairro',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Ex.: Serrano',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cityCtrl,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => _refreshFreeAddressPreview(),
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Ex.: Caxias do Sul, RS',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _complementCtrl,
                enabled: !_saving,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Complemento (opcional)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              if (_listening)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Ouvindo… fale rua e bairro',
                    style: TextStyle(color: AppColors.orange, fontSize: 12),
                  ),
                ),
              if (_speechError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _speechError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              _tipoChip(),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _orderCtrl,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Ordem na sacola (opcional)',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Ex.: 47 — deixe vazio se for pacote ++ (extra na rota)',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              enabled: !_saving,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Código / referência do pacote (opcional)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEdit ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}
