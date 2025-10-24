class BleDevice {
  final String id;
  final String name;
  final int rssi;
  final bool isConnectable;

  const BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.isConnectable,
  });

  String get displayName => name.isEmpty ? 'Unknown Device' : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BleDevice &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}