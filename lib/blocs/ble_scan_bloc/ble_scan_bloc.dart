import 'dart:async';
import 'package:ble_scanner/models/ble_device_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../repositories/ble_repository.dart';
import '../../../utils/permission_helper.dart';
import 'ble_scan_state.dart';

class BleScanBloc extends Cubit<BleScanState> {
  final BleRepository _bleRepository;
  StreamSubscription<List<BleDevice>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  final Map<String, BleDevice> _deviceMap = {}; // ✅ Track unique devices

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
          errorMessage: 'Bluetooth is not available on this device',
        ));
        return;
      }

      final hasPermissions = await PermissionHelper.hasRequiredPermissions;
      if (!hasPermissions) {
        emit(state.copyWith(
          status: BleScanStatus.permissionError,
          errorMessage: 'Bluetooth permissions required',
        ));
        return;
      }

      final isBluetoothOn = await _bleRepository.isBluetoothOn;

      if (!isBluetoothOn) {
        emit(state.copyWith(
          status: BleScanStatus.bluetoothOff,
          errorMessage: 'Please enable Bluetooth',
        ));
        _listenToBluetoothState();
        return;
      }

      _listenToBluetoothState();
      emit(state.copyWith(status: BleScanStatus.ready));
    } catch (e) {
      emit(state.copyWith(
        status: BleScanStatus.error,
        errorMessage: 'Failed to initialize: $e',
      ));
    }
  }

  void _listenToBluetoothState() {
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription =
        FlutterBluePlus.adapterState.listen((adapterState) {
          if (adapterState == BluetoothAdapterState.on) {
            if (state.status == BleScanStatus.bluetoothOff) {
              emit(state.copyWith(status: BleScanStatus.ready));
            }
          } else {
            if (state.status == BleScanStatus.scanning) {
              stopScan();
            }
            emit(state.copyWith(
              status: BleScanStatus.bluetoothOff,
              errorMessage: 'Please enable Bluetooth',
            ));
          }
        });
  }

  Future<void> startScan() async {
    try {
      await _scanSubscription?.cancel();
      _deviceMap.clear();

      await PermissionHelper.ensureLocationEnabled();

      final hasPermissions = await PermissionHelper.hasRequiredPermissions;
      if (!hasPermissions) {
        emit(state.copyWith(
          status: BleScanStatus.permissionError,
          errorMessage: 'Permissions required or location is off',
        ));
        return;
      }

      final isBluetoothOn = await _bleRepository.isBluetoothOn;
      if (!isBluetoothOn) {
        emit(state.copyWith(
          status: BleScanStatus.bluetoothOff,
          errorMessage: 'Bluetooth is off',
        ));
        return;
      }

      emit(state.copyWith(status: BleScanStatus.scanning, devices: []));

      await _bleRepository.startScan();

      // ✅ Stop after 15 seconds automatically
      Future.delayed(const Duration(seconds: 15), () {
        if (!isClosed && state.status == BleScanStatus.scanning) {
          stopScan();
        }
      });

      _scanSubscription = _bleRepository.scanResults.listen(
            (devices) {
          for (final device in devices) {
            _deviceMap[device.id] = device; // ✅ Maintain unique devices
          }

          if (!isClosed) {
            emit(state.copyWith(
              status: BleScanStatus.scanning,
              devices: _deviceMap.values.toList(),
            ));
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(state.copyWith(
              status: BleScanStatus.error,
              errorMessage: 'Scan error: $error',
            ));
          }
        },
      );

      _isScanningSubscription?.cancel();
      _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning && state.status == BleScanStatus.scanning) {
          if (!isClosed) {
            emit(state.copyWith(status: BleScanStatus.ready));
          }
        }
      });
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: BleScanStatus.error,
          errorMessage: 'Failed to start scan: $e',
        ));
      }
    }
  }

  Future<void> stopScan() async {
    try {
      await _bleRepository.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      if (!isClosed) {
        emit(state.copyWith(
          status: BleScanStatus.ready,
          devices: _deviceMap.values.toList(),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: BleScanStatus.error,
        errorMessage: 'Failed to stop scan: $e',
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
        errorMessage: 'Permissions denied. Please enable them in settings.',
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
