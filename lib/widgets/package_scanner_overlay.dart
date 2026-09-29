import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rota_prime/app/theme.dart';

/// Escurece fora da janela + cantos (mira).
class PackageScannerDimOverlay extends CustomPainter {
  PackageScannerDimOverlay(this.scanWindow, {this.cornerColor = AppColors.orange});

  final Rect scanWindow;
  final Color cornerColor;

  static const _cornerLen = 28.0;
  static const _stroke = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
    );
    final cut = Path.combine(PathOperation.difference, bg, hole);
    canvas.drawPath(
      cut,
      Paint()
        ..color = const Color(0xAA000000)
        ..style = PaintingStyle.fill,
    );

    final paint = Paint()
      ..color = cornerColor
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = scanWindow;
    void corner(Offset start, Offset hEnd, Offset vEnd) {
      canvas.drawLine(start, hEnd, paint);
      canvas.drawLine(start, vEnd, paint);
    }

    corner(r.topLeft, r.topLeft + Offset(_cornerLen, 0), r.topLeft + Offset(0, _cornerLen));
    corner(r.topRight, r.topRight + Offset(-_cornerLen, 0), r.topRight + Offset(0, _cornerLen));
    corner(r.bottomLeft, r.bottomLeft + Offset(_cornerLen, 0), r.bottomLeft + Offset(0, -_cornerLen));
    corner(r.bottomRight, r.bottomRight + Offset(-_cornerLen, 0), r.bottomRight + Offset(0, -_cornerLen));
  }

  @override
  bool shouldRepaint(covariant PackageScannerDimOverlay oldDelegate) =>
      oldDelegate.scanWindow != scanWindow;
}

/// Retângulo laranja em volta do código detectado (detector dinâmico).
class PackageBarcodeHighlightPainter extends CustomPainter {
  PackageBarcodeHighlightPainter({
    required this.barcodeCorners,
    required this.barcodeSize,
    required this.boxFit,
    required this.cameraPreviewSize,
  });

  final List<Offset> barcodeCorners;
  final Size barcodeSize;
  final BoxFit boxFit;
  final Size cameraPreviewSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (barcodeCorners.isEmpty ||
        barcodeSize.isEmpty ||
        cameraPreviewSize.isEmpty) {
      return;
    }

    final adjustedSize = applyBoxFit(boxFit, cameraPreviewSize, size);
    var verticalPadding = size.height - adjustedSize.destination.height;
    var horizontalPadding = size.width - adjustedSize.destination.width;
    verticalPadding = verticalPadding > 0 ? verticalPadding / 2 : 0;
    horizontalPadding = horizontalPadding > 0 ? horizontalPadding / 2 : 0;

    final double ratioWidth;
    final double ratioHeight;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      ratioWidth = barcodeSize.width / adjustedSize.destination.width;
      ratioHeight = barcodeSize.height / adjustedSize.destination.height;
    } else {
      ratioWidth = cameraPreviewSize.width / adjustedSize.destination.width;
      ratioHeight = cameraPreviewSize.height / adjustedSize.destination.height;
    }

    final points = [
      for (final offset in barcodeCorners)
        Offset(
          offset.dx / ratioWidth + horizontalPadding,
          offset.dy / ratioHeight + verticalPadding,
        ),
    ];
    if (points.length < 4) return;

    final path = Path()..addPolygon(points, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.orange.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant PackageBarcodeHighlightPainter oldDelegate) => true;
}

/// Overlay que segue o código na câmera.
class PackageBarcodeHighlightOverlay extends StatelessWidget {
  const PackageBarcodeHighlightOverlay({super.key, required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (!value.isInitialized || !value.isRunning || value.error != null) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<BarcodeCapture>(
          stream: controller.barcodes,
          builder: (context, snapshot) {
            final capture = snapshot.data;
            if (capture == null || capture.barcodes.isEmpty) {
              return const SizedBox.shrink();
            }
            final barcode = capture.barcodes.first;
            if (value.size.isEmpty ||
                barcode.size.isEmpty ||
                barcode.corners.isEmpty) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              painter: PackageBarcodeHighlightPainter(
                barcodeCorners: barcode.corners,
                barcodeSize: barcode.size,
                boxFit: BoxFit.cover,
                cameraPreviewSize: value.size,
              ),
              child: const SizedBox.expand(),
            );
          },
        );
      },
    );
  }
}
