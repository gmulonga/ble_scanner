import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device_model.dart';

class BleRepository {
  final List<BleDevice> _foundDevices = [];
  final Map<String, BluetoothDevice> _deviceMap = {};
  final Map<String, Stream<BluetoothConnectionState>> _connectionStreams = {};

  BluetoothDevice? getDeviceById(String deviceId) => _deviceMap[deviceId];

  Stream<BluetoothConnectionState>? getConnectionStateStream(String deviceId) {
    final device = _deviceMap[deviceId];
    return device?.connectionState;
  }

  Stream<List<BleDevice>> get scanResults {
    return FlutterBluePlus.scanResults.map((results) {
      for (var result in results) {
        final serviceUuids = result.advertisementData.serviceUuids
            .map((uuid) => uuid.toString())
            .toList();

        final device = BleDevice(
          id: result.device.remoteId.str,
          serviceUuids: serviceUuids,
          name: result.device.platformName.isNotEmpty
              ? result.device.platformName
              : "Unknown Device",
          rssi: result.rssi,
          isConnectable: result.advertisementData.connectable,
        );

        _deviceMap[device.id] = result.device;

        if (!_foundDevices.any((d) => d.id == device.id)) {
          _foundDevices.add(device);
        } else {
          final index = _foundDevices.indexWhere((d) => d.id == device.id);
          if (index != -1) {
            _foundDevices[index] =
                _foundDevices[index].copyWith(rssi: result.rssi);
          }
        }
      }
      return List<BleDevice>.from(_foundDevices);
    });
  }

  Future<void> startScan() async {
    _foundDevices.clear();
    _deviceMap.clear();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> stopScan() async => FlutterBluePlus.stopScan();

  Future<bool> get isBluetoothAvailable => FlutterBluePlus.isAvailable;
  Future<bool> get isBluetoothOn => FlutterBluePlus.isOn;

  Future<void> connectToDevice(String deviceId) async {
    final device = _deviceMap[deviceId];
    if (device != null) {
      await device.connect();
    } else {
      throw Exception("Device not found. Please scan first.");
    }
  }

  Future<void> disconnectFromDevice(String deviceId) async {
    final device = _deviceMap[deviceId];
    if (device != null) {
      await device.disconnect();
    } else {
      throw Exception("Device not found. Please scan first.");
    }
  }

  Future<List<BluetoothService>> discoverServices(String deviceId) async {
    final device = _deviceMap[deviceId];
    if (device != null) {
      return await device.discoverServices();
    } else {
      throw Exception("Device not found. Please scan first.");
    }
  }

  Future<int> readDeviceRssi(String deviceId) async {
    final device = _deviceMap[deviceId];
    if (device == null) {
      throw Exception("Device not found");
    }
    return await device.readRssi();
  }

  Future<List<BleDevice>> getConnectedDevices() async {
    final connectedDevices = await FlutterBluePlus.connectedDevices;
    final List<BleDevice> bleDevices = [];

    for (var device in connectedDevices) {
      final services = await device.discoverServices();
      final serviceUuids =
      services.map((s) => s.uuid.toString()).toList(growable: false);

      bleDevices.add(BleDevice(
        id: device.remoteId.str,
        serviceUuids: serviceUuids,
        name: device.platformName.isNotEmpty
            ? device.platformName
            : "Connected Device",
        rssi: 0,
        isConnectable: true,
      ));

      _deviceMap[device.remoteId.str] = device;
    }

    return bleDevices;
  }
}
