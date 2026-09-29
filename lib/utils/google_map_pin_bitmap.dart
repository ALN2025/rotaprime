import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rota_prime/app/theme.dart';

final _pinCache = <String, BitmapDescriptor>{};

const _cacheVersion = 'rp2';

Future<BitmapDescriptor> googleMapPinIcon(
  String label, {
  bool selected = false,
  bool compact = false,
}) async {
  final key = '$_cacheVersion|pin|$label|$selected|$compact';
  final cached = _pinCache[key];
  if (cached != null) return cached;

  final w = compact ? 34.0 : (selected ? 44.0 : 40.0);
  final h = compact ? 44.0 : (selected ? 54.0 : 50.0);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _drawRotaPrimeStopPin(
    canvas,
    Size(w, h),
    label: label.length > 4 ? label.substring(0, 4) : label,
    selected: selected,
    compact: compact,
  );

  final img = await recorder.endRecording().toImage(w.ceil(), h.ceil());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final icon = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  _pinCache[key] = icon;
  return icon;
}

Future<BitmapDescriptor> googleMapDriverIcon({bool navigationMode = true}) async {
  final key = '$_cacheVersion|driver|$navigationMode';
  if (_pinCache.containsKey(key)) return _pinCache[key]!;

  const size = 48.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _drawRotaPrimeDriverArrow(canvas, const Size(size, size), bold: navigationMode);

  final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final icon = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  _pinCache[key] = icon;
  return icon;
}

void _drawRotaPrimeStopPin(
  Canvas canvas,
  Size size, {
  required String label,
  required bool selected,
  required bool compact,
}) {
  final fill = selected ? AppColors.orange : const Color(0xFF5C5C66);
  final headR = size.width * 0.38;
  final headCenter = Offset(size.width / 2, headR + 2);
  final tipY = size.height - 1;

  final path = Path()
    ..moveTo(headCenter.dx, tipY)
    ..quadraticBezierTo(
      headCenter.dx - headR * 0.35,
      headCenter.dy + headR * 0.85,
      headCenter.dx - headR,
      headCenter.dy,
    )
    ..arcToPoint(
      Offset(headCenter.dx + headR, headCenter.dy),
      radius: Radius.circular(headR),
      clockwise: true,
    )
    ..quadraticBezierTo(
      headCenter.dx + headR * 0.35,
      headCenter.dy + headR * 0.85,
      headCenter.dx,
      tipY,
    )
    ..close();

  canvas.drawShadow(path, Colors.black.withValues(alpha: 0.45), 3, false);
  canvas.drawPath(path, Paint()..color = fill);
  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.white.withValues(alpha: selected ? 1 : 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.5 : 1.8,
  );

  if (selected) {
    canvas.drawCircle(
      headCenter,
      headR + 4,
      Paint()
        ..color = AppColors.orange.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: compact ? 10 : (label.length > 2 ? 11 : 13),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: headR * 1.6);
  tp.paint(canvas, headCenter - Offset(tp.width / 2, tp.height / 2));
}

void _drawRotaPrimeDriverArrow(Canvas canvas, Size size, {required bool bold}) {
  final center = Offset(size.width / 2, size.height / 2);
  final r = size.width / 2 - 2;

  canvas.drawCircle(
    center,
    r,
    Paint()..color = AppColors.orange,
  );
  canvas.drawCircle(
    center,
    r,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = bold ? 3.5 : 3,
  );
  canvas.drawCircle(
    center,
    r + 3,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );

  final arrowH = r * (bold ? 1.05 : 0.95);
  final path = Path()
    ..moveTo(center.dx, center.dy - arrowH * 0.55)
    ..lineTo(center.dx - arrowH * 0.42, center.dy + arrowH * 0.35)
    ..lineTo(center.dx, center.dy + arrowH * 0.08)
    ..lineTo(center.dx + arrowH * 0.42, center.dy + arrowH * 0.35)
    ..close();

  canvas.drawPath(path, Paint()..color = Colors.white);
  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );

}
