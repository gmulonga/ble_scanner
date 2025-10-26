class BleDevice {
  final String id;
  final List<String> serviceUuids;
  final String name;
  final int rssi;
  final bool isConnectable;

  const BleDevice({
    required this.id,
    required this.serviceUuids,
    required this.name,
    required this.rssi,
    required this.isConnectable,
  });

  BleDevice copyWith({
    String? id,
    List<String>? serviceUuids,
    String? name,
    int? rssi,
    bool? isConnectable,
  }) {
    return BleDevice(
      id: id ?? this.id,
      serviceUuids: serviceUuids ?? this.serviceUuids,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      isConnectable: isConnectable ?? this.isConnectable,
    );
  }

  String get displayName => name.isEmpty ? 'Unknown Device' : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BleDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
