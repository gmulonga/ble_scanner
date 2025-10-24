import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionHelper {
  static Future<bool> requestBluetoothPermissions() async {
    final permissions = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return permissions.values.every((status) => status.isGranted);
  }

  static Future<bool> get hasRequiredPermissions async {
    final statuses = await Future.wait([
      Permission.bluetooth.status,
      Permission.bluetoothScan.status,
      Permission.bluetoothConnect.status,
      Permission.locationWhenInUse.status,
    ]);

    return statuses.every((status) => status.isGranted);
  }

  static Future<void> ensureLocationEnabled() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      await Geolocator.openLocationSettings();
    }
  }
}
