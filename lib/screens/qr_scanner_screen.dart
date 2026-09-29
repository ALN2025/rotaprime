import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/services/camera_permission.dart';
import 'package:rota_prime/utils/parada_scan_match.dart';
import 'package:rota_prime/utils/spx_regex.dart';
import 'package:rota_prime/widgets/package_scanner_overlay.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, this.returnAddedParada = false});

  final bool returnAddedParada;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _dialogOpen = false;
  bool _permissionOk = false;
  String? _fatalError;
  bool _permanentDenial = false;
  String? _lastRawCode;
  DateTime? _lastDetectAt;

  List<Offset> _highlightCorners = const [];
  Size _previewSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: false,
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_permissionOk || _dialogOpen) return;
    if (!_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        return;
      case AppLifecycleState.paused:
        unawaited(_controller.stop());
      case AppLifecycleState.resumed:
        unawaited(_startCamera(resumeOnly: true));
    }
  }

  Future<void> _startCamera({bool resumeOnly = false}) async {
    if (!resumeOnly) {
      setState(() {
        _fatalError = null;
        _permanentDenial = false;
      });

      final ok = await ensureCameraPermission();
      if (!mounted) return;
      if (!ok) {
        final st = await Permission.camera.status;
        setState(() {
          _permissionOk = false;
          _permanentDenial = st.isPermanentlyDenied;
          _fatalError = _permanentDenial
              ? 'Permissão da câmera bloqueada. Abra Configurações e permita.'
              : 'Permissão da câmera negada.';
        });
        return;
      }
      if (!mounted) return;
      setState(() => _permissionOk = true);
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }

    try {
      if (!_controller.value.isRunning) {
        await _controller.start();
      }
      if (!mounted) return;
      final err = _controller.value.error;
      if (err != null) {
        setState(() => _fatalError = _ptError(err));
      } else if (_fatalError != null) {
        setState(() => _fatalError = null);
      }
    } on MobileScannerException catch (e) {
      if (!mounted) return;
      setState(() => _fatalError = _ptError(e));
    }
  }

  String _ptError(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Permissão da câmera negada.';
      case MobileScannerErrorCode.unsupported:
        return 'Leitura de código não suportada neste aparelho.';
      case MobileScannerErrorCode.controllerAlreadyInitialized:
        return 'Câmera já em uso. Feche e abra de novo.';
      default:
        final detail = e.errorDetails?.message?.trim();
        if (detail != null && detail.isNotEmpty) {
          return 'Erro na câmera ($detail). Toque em Tentar de novo.';
        }
        return 'Não foi possível iniciar a câmera. Toque em Tentar de novo.';
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_dialogOpen) return;

    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    if (barcode != null &&
        barcode.corners.length >= 4 &&
        capture.size.width > 0 &&
        capture.size.height > 0) {
      setState(() {
        _highlightCorners = barcode.corners;
        _previewSize = capture.size;
      });
    }

    final now = DateTime.now();
    if (_lastRawCode == raw &&
        _lastDetectAt != null &&
        now.difference(_lastDetectAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastRawCode = raw;
    _lastDetectAt = now;

    final code = extractTrackingCode(raw) ??
        (looksLikeTrackingCode(raw) ? raw.trim().toUpperCase() : null);
    if (code == null || code.length < 4) return;

    final paradas = ref.read(rotaProvider).paradas;
    final existing = findParadaForScanCode(paradas, raw);
    if (existing != null) {
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      if (widget.returnAddedParada) {
        Navigator.of(context).pop(existing);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pacote $code · parada ${existing.ordemExibicao}')),
      );
      navigateToRouteMap(context, ref);
      return;
    }

    _dialogOpen = true;
    await HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    await _controller.stop();

    final address = await ref.read(rotaProvider.notifier).findAddressForSpx(code);
    if (!mounted) return;

    final addressCtrl = TextEditingController(text: address ?? '');

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1A1A1A),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Código: $code',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final addr = addressCtrl.text.trim();
                    if (addr.isEmpty) return;
                    final parada =
                        await ref.read(rotaProvider.notifier).addParadaFromQr(code, addr);
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    if (!mounted) return;
                    if (widget.returnAddedParada) {
                      Navigator.of(context).pop(parada);
                      return;
                    }
                    navigateToRouteMap(context, ref);
                  },
                  style: primaryOrangeButtonStyle(),
                  child: const Text('Adicionar à rota'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      _dialogOpen = false;
      addressCtrl.dispose();
      if (mounted && _permissionOk) {
        unawaited(_startCamera(resumeOnly: true));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(rotaProvider.select((s) => s.pacotesEscaneados));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('$count pacotes escaneados'),
        actions: [
          if (_permissionOk && _fatalError == null)
            IconButton(
              tooltip: 'Lanterna',
              onPressed: () => _controller.toggleTorch(),
              icon: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, state, _) {
                  switch (state.torchState) {
                    case TorchState.on:
                      return const Icon(Icons.flash_on, color: AppColors.orange);
                    default:
                      return const Icon(Icons.flash_off_outlined);
                  }
                },
              ),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_fatalError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                _fatalError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 20),
              if (_permanentDenial)
                OutlinedButton(
                  onPressed: openAppSettings,
                  child: const Text('Abrir configurações'),
                ),
              ElevatedButton(
                onPressed: () => _startCamera(),
                style: primaryOrangeButtonStyle(),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_permissionOk) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }

    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset.zero),
      width: 280,
      height: 280,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          fit: BoxFit.cover,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _fatalError == null) {
                setState(() => _fatalError = _ptError(error));
              }
            });
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          },
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: PackageScannerDimOverlay(scanWindow),
            child: const SizedBox.expand(),
          ),
        ),
        if (_highlightCorners.length >= 4 && _previewSize.width > 0)
          IgnorePointer(
            child: CustomPaint(
              painter: PackageBarcodeHighlightPainter(
                barcodeCorners: _highlightCorners,
                barcodeSize: _previewSize,
                boxFit: BoxFit.cover,
                cameraPreviewSize: _previewSize,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final detecting = state.isRunning && state.error == null;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    detecting
                        ? 'Aponte para o QR ou código de barras do pacote'
                        : 'Iniciando câmera…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'O retângulo laranja segue o código detectado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
