import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class DriverFix {
  const DriverFix({
    required this.position,
    required this.headingDegrees,
    required this.speedMps,
  });

  final LatLng position;
  /// 0 = norte, sentido horário (bússola / movimento).
  final double headingDegrees;
  final double speedMps;
}

class LocationService {
  final _distance = const Distance();

  Future<bool> ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<LatLng?> getCurrentLatLng() async {
    final fix = await getCurrentFix();
    return fix?.position;
  }

  /// Otimização de rota: não trava minutos esperando GPS de alta precisão.
  Future<LatLng?> getCurrentLatLngQuick() async {
    final ok = await ensurePermission();
    if (!ok) return null;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<DriverFix?> getCurrentFix() async {
    final ok = await ensurePermission();
    if (!ok) return null;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return _fixFromPosition(pos, null);
  }

  Stream<DriverFix> watchDriver({double distanceFilterMeters = 2}) async* {
    final ok = await ensurePermission();
    if (!ok) return;
    LatLng? lastPos;
    double lastHeading = 0;

    await for (final pos in Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters.toInt(),
      ),
    )) {
      final fix = _fixFromPosition(pos, lastPos, fallbackHeading: lastHeading);
      lastPos = fix.position;
      lastHeading = fix.headingDegrees;
      yield fix;
    }
  }

  DriverFix _fixFromPosition(
    Position pos,
    LatLng? previous, {
    double fallbackHeading = 0,
  }) {
    final current = LatLng(pos.latitude, pos.longitude);
    var heading = fallbackHeading;

    if (pos.heading >= 0 && pos.speed >= 0.8) {
      heading = pos.heading;
    } else if (previous != null) {
      final meters = _distance(previous, current);
      if (meters >= 3) {
        heading = _distance.bearing(previous, current);
      }
    }

    return DriverFix(
      position: current,
      headingDegrees: heading,
      speedMps: pos.speed,
    );
  }
}
