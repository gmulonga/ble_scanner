import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device_model.dart';

class BleRepository {
  final List<BleDevice> _foundDevices = [];

  Stream<List<BleDevice>> get scanResults {
    return FlutterBluePlus.scanResults.map((results) {
      for (var result in results) {
        final device = BleDevice(
          id: result.device.remoteId.str,
          name: result.device.platformName.isNotEmpty
              ? result.device.platformName
              : "Unknown Device",
          rssi: result.rssi,
          isConnectable: result.advertisementData.connectable,
        );

        // Only add if it's not already in the list
        if (!_foundDevices.any((d) => d.id == device.id)) {
          _foundDevices.add(device);
        }
      }
      return List<BleDevice>.from(_foundDevices);
    });
  }

  Future<void> startScan() async {
    _foundDevices.clear();
    await FlutterBluePlus.startScan();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<bool> get isBluetoothAvailable => FlutterBluePlus.isAvailable;
  Future<bool> get isBluetoothOn => FlutterBluePlus.isOn;
}

