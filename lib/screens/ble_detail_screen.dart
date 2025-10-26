import 'dart:async';

import 'package:ble_scanner/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../blocs/ble_scan_bloc/ble_scan_bloc.dart';
import '../blocs/ble_scan_bloc/ble_scan_state.dart';
import '../models/ble_device_model.dart';
import '../widgets/custom_snackbar.dart';

class DeviceDetailScreen extends StatefulWidget {
  final BleDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _isConnecting = false;
  bool _isLoadingServices = false;
  List<BluetoothService> _services = [];
  BluetoothConnectionState? _connectionState;
  String? _lastSnackMessage;
  bool _hasRetried = false;

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  void _startConnectionListener() {
    final repo = context.read<BleScanBloc>().repository;
    final stream = repo.getConnectionStateStream(widget.device.id);
    if (stream == null) return;

    _connectionSubscription?.cancel();
    _connectionSubscription = stream.listen((state) async {
      if (!mounted) return;
      setState(() => _connectionState = state);

      void showOnce(String msg, Color color) {
        if (_lastSnackMessage != msg) {
          _lastSnackMessage = msg;
          CustomSnackBar.show(context, msg, color);
        }
      }

      switch (state) {
        case BluetoothConnectionState.connected:
          _hasRetried = false;
          showOnce('Device connected', Colors.green);
          break;
        case BluetoothConnectionState.connecting:
          showOnce('Connecting...', Colors.blue);
          break;
        case BluetoothConnectionState.disconnecting:
          showOnce('Disconnecting...', Colors.orange);
          break;
        case BluetoothConnectionState.disconnected:
          showOnce('Device disconnected', Colors.red);
          if (!_hasRetried) {
            _hasRetried = true;
            _attemptReconnection();
          }
          break;
      }
    });
  }

  Future<void> _attemptReconnection() async {
    final repo = context.read<BleScanBloc>().repository;

    for (int i = 1; i <= 2; i++) {
      if (!mounted) return;

      CustomSnackBar.show(context, 'Reconnecting ...', Colors.orange);

      try {
        await repo.connectToDevice(widget.device.id);
        _discoverServices(context);
        return;
      } catch (_) {
        await Future.delayed(const Duration(seconds: 4));
      }
    }

    CustomSnackBar.show(context, 'Failed to reconnect after 2 attempts', Colors.redAccent);
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }

  String _getSignalStrength(int rssi) {
    if (rssi >= -60) return 'Excellent';
    if (rssi >= -70) return 'Good';
    if (rssi >= -80) return 'Fair';
    return 'Weak';
  }

  double _getSignalPercentage(int rssi) {
    final percentage = ((rssi + 100) / 70 * 100).clamp(0.0, 100.0);
    return percentage;
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    CustomSnackBar.show(context, 'copied to clipboard', kPrimary);

  }

  Future<void> _discoverServices(BuildContext context) async {
    setState(() {
      _isLoadingServices = true;
      _services.clear();
    });
    try {
      final repo = context.read<BleScanBloc>().repository;
      final services = await repo.discoverServices(widget.device.id);
      setState(() {
        _services = services;
      });
    } catch (e) {
      // CustomSnackBar.show(context, 'Failed to load services: $e', kRed);
    } finally {
      setState(() => _isLoadingServices = false);
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Device Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: BlocConsumer<BleScanBloc, BleScanState>(
        listener: (context, state) {
          if (state.status == BleScanStatus.error) {
            CustomSnackBar.show(context, 'Unknown Error', kRed);
          }
        },
        builder: (context, state) {
          // ✅ Access the device info dynamically from the BLoC state
          final updatedDevice = state.devices.firstWhere(
                (d) => d.id == widget.device.id,
            orElse: () => widget.device,
          );

          final signalColor = _getSignalColor(updatedDevice.rssi);
          final signalStrength = _getSignalStrength(updatedDevice.rssi);
          final signalPercentage = _getSignalPercentage(updatedDevice.rssi);
          final isConnected = state.connectedDevices[widget.device.id] ?? false;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(signalColor),
                const SizedBox(height: 16),
                _buildSignalCard(signalColor, signalStrength, signalPercentage, updatedDevice),
                _buildInfoCard(context, updatedDevice),
                _buildActions(context, isConnected),
                if (isConnected) _buildServiceList(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Color signalColor) {
    final state = _connectionState ?? BluetoothConnectionState.disconnected;
    String statusText;
    Color statusColor;

    switch (state) {
      case BluetoothConnectionState.connected:
        statusText = 'Connected';
        statusColor = Colors.green;
        break;
      case BluetoothConnectionState.connecting:
        statusText = 'Connecting';
        statusColor = Colors.blue;
        break;
      case BluetoothConnectionState.disconnecting:
        statusText = 'Disconnecting';
        statusColor = Colors.orange;
        break;
      default:
        statusText = 'Disconnected';
        statusColor = Colors.red;
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.bluetooth, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            widget.device.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: statusColor, size: 8),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSignalCard(Color signalColor, String signalStrength, double signalPercentage, BleDevice updatedDevice) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Signal Strength',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: signalColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                signalStrength,
                style: TextStyle(
                  color: signalColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: signalColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.signal_cellular_alt, color: signalColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${updatedDevice.rssi} dBm',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: signalColor)),
                      Text('${signalPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: signalPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        color: signalColor,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, BleDevice updatedDevice) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Device Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _buildInfoRow(context,
              icon: Icons.badge_outlined,
              label: 'Device Name',
              value: updatedDevice.displayName,
              onCopy: () => _copyToClipboard(context, updatedDevice.displayName, 'Device name')),
          const Divider(height: 24),
          _buildInfoRow(context,
              icon: Icons.fingerprint,
              label: 'Device ID',
              value: updatedDevice.id,
              isMonospace: true,
              onCopy: () => _copyToClipboard(context, updatedDevice.id, 'Device ID')),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isConnected) {
    return _buildCard(
      child: Column(
        children: [
          _buildActionButton(
            icon: isConnected ? Icons.link_off : Icons.link,
            label: _isConnecting
                ? 'Connecting...'
                : (isConnected ? 'Disconnect' : 'Connect'),
            color: isConnected ? kRed : kPrimary,
            onPressed: _isConnecting
                ? null
                : () async {
              setState(() => _isConnecting = true);
              final bloc = context.read<BleScanBloc>();

              try {
                if (isConnected) {
                  await bloc.disconnectDevice(widget.device.id);
                  CustomSnackBar.show(context, 'Disconnected', kPrimary);
                } else {
                  await bloc.connectDevice(widget.device.id);
                  _startConnectionListener();
                  await _discoverServices(context);
                }
              } catch (e) {
                CustomSnackBar.show(context, 'Connection error: $e', kRed);
              } finally {
                setState(() => _isConnecting = false);
              }
            },
          ),
          const SizedBox(height: 12),
          if (isConnected)
            _buildActionButton(
              icon: Icons.refresh,
              label: 'Reconnect',
              color: Colors.green,
              onPressed: _attemptReconnection,
            ),
        ],
      ),
    );
  }

  String _getCharacteristicProperties(BluetoothCharacteristic c) {
    final props = <String>[];

    if (c.properties.read) props.add("Read");
    if (c.properties.write) props.add("Write");
    if (c.properties.writeWithoutResponse) props.add("WriteNoResp");
    if (c.properties.notify) props.add("Notify");
    if (c.properties.indicate) props.add("Indicate");
    if (c.properties.authenticatedSignedWrites) props.add("SignedWrite");

    return props.join(", ");
  }

  Widget _buildServiceList() {
    if (_services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                "No services discovered yet",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 10),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.dns, color: Colors.blue[700], size: 20),
              ),
              title: Text(
                service.uuid.str,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${service.characteristics.length} characteristics',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              children: service.characteristics.map((char) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              char.uuid.str,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getCharacteristicProperties(char),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
        required String label,
        required String value,
        bool isMonospace = false,
        VoidCallback? onCopy}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue[700], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontFamily: isMonospace ? 'monospace' : null,
                  )),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: Colors.grey[600]),
            onPressed: onCopy,
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
