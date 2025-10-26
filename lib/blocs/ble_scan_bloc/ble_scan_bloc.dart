import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../models/ble_device_model.dart';
import '../../../repositories/ble_repository.dart';
import '../../../utils/permission_helper.dart';
import 'ble_scan_state.dart';

class BleScanBloc extends Cubit<BleScanState> {
  final BleRepository _bleRepository;
  BleRepository get repository => _bleRepository;

  StreamSubscription<List<BleDevice>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  final Map<String, BleDevice> _deviceMap = {};

  BleScanBloc()
      : _bleRepository = BleRepository(),
        super(const BleScanState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final isAvailable = await _bleRepository.isBluetoothAvailable;
      if (!isAvailable) {
        emit(state.copyWith(
          status: BleScanStatus.error,
          errorMessage: 'Bluetooth not available on this device.',
        ));
        return;
      }

      final hasPermissions = await PermissionHelper.hasRequiredPermissions;
      if (!hasPermissions) {
        emit(state.copyWith(
          status: BleScanStatus.permissionError,
          errorMessage: 'Bluetooth permissions required.',
        ));
        return;
      }

      final isBluetoothOn = await _bleRepository.isBluetoothOn;
      if (!isBluetoothOn) {
        emit(state.copyWith(
          status: BleScanStatus.bluetoothOff,
          errorMessage: 'Please enable Bluetooth.',
        ));
      } else {
        emit(state.copyWith(status: BleScanStatus.ready));
      }

      _listenToBluetoothState();
    } catch (e) {
      emit(state.copyWith(
        status: BleScanStatus.error,
        errorMessage: 'Initialization failed: $e',
      ));
    }
  }

  void _listenToBluetoothState() {
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription =
        FlutterBluePlus.adapterState.listen((adapterState) {
          if (adapterState == BluetoothAdapterState.on) {
            emit(state.copyWith(status: BleScanStatus.ready));
          } else {
            stopScan();
            emit(state.copyWith(
              status: BleScanStatus.bluetoothOff,
              errorMessage: 'Bluetooth turned off.',
            ));
          }
        });
  }

  Future<void> startScan() async {
    try {
      await loadConnectedDevices();
      await _scanSubscription?.cancel();
      _deviceMap.clear();

      await PermissionHelper.ensureLocationEnabled();
      final hasPermissions = await PermissionHelper.hasRequiredPermissions;
      if (!hasPermissions) {
        emit(state.copyWith(
          status: BleScanStatus.permissionError,
          errorMessage: 'Bluetooth or location permissions required.',
        ));
        return;
      }

      final isBluetoothOn = await _bleRepository.isBluetoothOn;
      if (!isBluetoothOn) {
        emit(state.copyWith(
          status: BleScanStatus.bluetoothOff,
          errorMessage: 'Bluetooth is off.',
        ));
        return;
      }

      emit(state.copyWith(status: BleScanStatus.scanning, devices: []));

      await _bleRepository.startScan();

      Future.delayed(const Duration(seconds: 15), () {
        if (!isClosed && state.status == BleScanStatus.scanning) {
          stopScan();
        }
      });

      _scanSubscription = _bleRepository.scanResults.listen(
            (devices) {
          for (final device in devices) {
            _deviceMap[device.id] = device;
          }
          if (!isClosed) {
            emit(state.copyWith(
              status: BleScanStatus.scanning,
              devices: _deviceMap.values.toList(),
            ));
          }
        },
        onError: (error) {
          emit(state.copyWith(
            status: BleScanStatus.error,
            errorMessage: 'Scan error: $error',
          ));
        },
      );

      _isScanningSubscription?.cancel();
      _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isClosed && !isScanning) {
          emit(state.copyWith(status: BleScanStatus.ready));
        }
      });
    } catch (e) {
      emit(state.copyWith(
        status: BleScanStatus.error,
        errorMessage: 'Failed to start scan: $e',
      ));
    }
  }

  Future<void> stopScan() async {
    try {
      await _bleRepository.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      emit(state.copyWith(
        status: BleScanStatus.ready,
        devices: _deviceMap.values.toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BleScanStatus.error,
        errorMessage: 'Failed to stop scan: $e',
      ));
    }
  }

  Future<void> connectDevice(String deviceId) async {
    try {
      await _bleRepository.connectToDevice(deviceId);

      final updatedConnections = Map<String, bool>.from(state.connectedDevices);
      updatedConnections[deviceId] = true;

      emit(state.copyWith(connectedDevices: updatedConnections));
    } catch (e) {
      emit(state.copyWith(
        status: BleScanStatus.error,
        errorMessage: 'Failed to connect: $e',
      ));
    }
  }

  Future<void> disconnectDevice(String deviceId) async {
    try {
      await _bleRepository.disconnectFromDevice(deviceId);

      final updatedConnections = Map<String, bool>.from(state.connectedDevices);
      updatedConnections[deviceId] = false;

      emit(state.copyWith(connectedDevices: updatedConnections));
    } catch (e) {
      emit(state.copyWith(
        status: BleScanStatus.error,
        errorMessage: 'Failed to disconnect: $e',
      ));
    }
  }

  Future<void> requestPermissions() async {
    final granted = await PermissionHelper.requestBluetoothPermissions();
    if (granted) {
      await _initialize();
    } else {
      emit(state.copyWith(
        status: BleScanStatus.permissionError,
        errorMessage: 'Bluetooth permissions denied. Enable them in settings.',
      ));
    }
  }

  Future<void> refreshRssi(String deviceId) async {
    try {
      final rssi = await _bleRepository.readDeviceRssi(deviceId);

      final updatedList = List<BleDevice>.from(state.devices);
      final index = updatedList.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        final oldDevice = updatedList[index];
        updatedList[index] = BleDevice(
          serviceUuids: oldDevice.serviceUuids,
          id: oldDevice.id,
          name: oldDevice.name,
          rssi: rssi,
          isConnectable: oldDevice.isConnectable,
        );
      }

      emit(state.copyWith(devices: updatedList));
    } catch (e) {
      emit(state.copyWith(
        status: BleScanStatus.error,
        errorMessage: 'Failed to refresh RSSI: $e',
      ));
    }
  }

  Future<void> loadConnectedDevices() async {
    try {
      final connectedDevices = await _bleRepository.getConnectedDevices();
      for (final device in connectedDevices) {
        _deviceMap[device.id] = device;
      }

      emit(state.copyWith(
        devices: _deviceMap.values.toList(),
        connectedDevices: {
          for (final d in connectedDevices) d.id: true,
        },
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BleScanStatus.error,
        errorMessage: 'Failed to load connected devices: $e',
      ));
    }
  }

  @override
  Future<void> close() async {
    await _scanSubscription?.cancel();
    await _adapterStateSubscription?.cancel();
    await _isScanningSubscription?.cancel();
    await _bleRepository.stopScan();
    return super.close();
  }
}
