import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/navigation/route_shell_navigation.dart';
import 'package:rota_prime/utils/parada_scan_match.dart';
import 'package:rota_prime/utils/spx_regex.dart';
import 'package:rota_prime/widgets/package_scanner_overlay.dart';

/// Leitor QR/código de barras — [MobileScanner] padrão (câmera gerenciada pelo plugin).
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, this.returnAddedParada = false});

  final bool returnAddedParada;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  int _scannerKey = 0;
  bool _dialogOpen = false;
  String? _lastRawCode;
  DateTime? _lastDetectAt;
  String? _lastCameraError;
  bool _lastErrorIsPermission = false;

  List<Offset> _highlightCorners = const [];
  Size _previewSize = Size.zero;

  void _remountScanner() {
    setState(() {
      _scannerKey++;
      _lastCameraError = null;
      _lastErrorIsPermission = false;
    });
  }

  String _ptError(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Permissão da câmera negada. Toque em Abrir configurações.';
      case MobileScannerErrorCode.unsupported:
        return 'Este aparelho não suporta leitura de código pela câmera.';
      default:
        final detail = e.errorDetails?.message?.trim();
        if (detail != null && detail.isNotEmpty) {
          return detail;
        }
        return 'Não foi possível abrir a câmera.';
    }
  }

  Future<void> _manualPackageCode() async {
    final codeCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    String? code;
    String? addr;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.sheet,
          title: const Text('Código do pacote', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'QR / código de barras',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
              onPressed: () {
                code = codeCtrl.text.trim();
                addr = addrCtrl.text.trim();
                Navigator.pop(ctx);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
    codeCtrl.dispose();
    addrCtrl.dispose();
    if (!mounted) return;
    final c = code;
    final a = addr;
    if (c == null || a == null || c.length < 4 || a.isEmpty) return;

    final parada = await ref.read(rotaProvider.notifier).addParadaFromQr(c, a);
    if (!mounted) return;
    if (widget.returnAddedParada) {
      Navigator.of(context).pop(parada);
      return;
    }
    navigateToRouteMap(context, ref);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(rotaProvider.select((s) => s.pacotesEscaneados));
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset.zero),
      width: 280,
      height: 280,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('$count pacotes escaneados'),
        actions: [
          TextButton(
            onPressed: _manualPackageCode,
            child: const Text('Digitar', style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_lastCameraError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white54),
                    const SizedBox(height: 12),
                    Text(
                      _lastCameraError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    if (_lastErrorIsPermission)
                      OutlinedButton(
                        onPressed: openAppSettings,
                        child: const Text('Abrir configurações'),
                      ),
                    ElevatedButton(
                      onPressed: _remountScanner,
                      style: primaryOrangeButtonStyle(),
                      child: const Text('Tentar de novo'),
                    ),
                    TextButton(
                      onPressed: _manualPackageCode,
                      child: const Text('Digitar código manualmente'),
                    ),
                  ],
                ),
              ),
            )
          else
            MobileScanner(
              key: ValueKey<int>(_scannerKey),
              fit: BoxFit.cover,
              useAppLifecycleState: false,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                final msg = _ptError(error);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _lastCameraError != msg) {
                    setState(() {
                      _lastCameraError = msg;
                      _lastErrorIsPermission =
                          error.errorCode == MobileScannerErrorCode.permissionDenied;
                    });
                  }
                });
                return Center(
                  child: Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
          if (_lastCameraError == null) ...[
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
              child: Text(
                'Aponte para o QR ou código de barras do pacote',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
