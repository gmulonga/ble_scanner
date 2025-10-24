import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device_model.dart';

class BleRepository {
  final List<BleDevice> _foundDevices = [];
  final Map<String, BluetoothDevice> _deviceMap = {};

  Stream<List<BleDevice>> get scanResults {
    return FlutterBluePlus.scanResults.map((results) {
      for (var result in results) {
        final device = BleDevice(
          id: result.device.remoteId.str,
          name: result.device.name.isNotEmpty
              ? result.device.name
              : "Unknown Device",
          rssi: result.rssi,
          isConnectable: result.advertisementData.connectable,
        );

        _deviceMap[device.id] = result.device;

        if (!_foundDevices.any((d) => d.id == device.id)) {
          _foundDevices.add(device);
        }
      }
      return List<BleDevice>.from(_foundDevices);
    });
  }

  Future<void> startScan() async {
    _foundDevices.clear();
    _deviceMap.clear();

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<bool> get isBluetoothAvailable => FlutterBluePlus.isAvailable;
  Future<bool> get isBluetoothOn => FlutterBluePlus.isOn;

  Future<void> connectToDevice(String deviceId) async {
    final device = _deviceMap[deviceId];
    if (device != null) {
      await device.connect();
    } else {
      throw Exception("Device not found. Scan first.");
    }
  }

  Future<void> disconnectFromDevice(String deviceId) async {
    final device = _deviceMap[deviceId];
    if (device != null) {
      await device.disconnect();
    } else {
      throw Exception("Device not found. Scan first.");
    }
  }

  Future<List<BluetoothService>> discoverServices(String deviceId) async {
    final device = _deviceMap[deviceId];
    if (device != null) {
      return await device.discoverServices();
    } else {
      throw Exception("Device not found. Scan first.");
    }
  }
}