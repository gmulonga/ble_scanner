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
  final String? errorMessage;

  const BleScanState({
    required this.status,
    required this.devices,
    this.errorMessage,
  });

  const BleScanState.initial()
      : status = BleScanStatus.initial,
        devices = const [],
        errorMessage = null;

  BleScanState copyWith({
    BleScanStatus? status,
    List<BleDevice>? devices,
    String? errorMessage,
  }) {
    return BleScanState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}