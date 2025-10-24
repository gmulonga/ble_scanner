import '../../models/ble_device_model.dart';

enum BleScanStatus {
  initial,
  ready,
  scanning,
  bluetoothOff,
  permissionError,
  error,
}

class BleScanState {
  final BleScanStatus status;
  final List<BleDevice> devices;
  final Map<String, bool> connectedDevices;
  final String? errorMessage;

  const BleScanState({
    required this.status,
    required this.devices,
    this.connectedDevices = const {},
    this.errorMessage,
  });

  const BleScanState.initial()
      : status = BleScanStatus.initial,
        devices = const [],
        connectedDevices = const {},
        errorMessage = null;

  BleScanState copyWith({
    BleScanStatus? status,
    List<BleDevice>? devices,
    Map<String, bool>? connectedDevices,
    String? errorMessage,
  }) {
    return BleScanState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}