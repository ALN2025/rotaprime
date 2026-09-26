import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureMicrophonePermission() async {
  var status = await Permission.microphone.status;
  if (status.isGranted) return true;
  status = await Permission.microphone.request();
  return status.isGranted;
}
