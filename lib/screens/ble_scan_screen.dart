import 'package:ble_scanner/models/ble_device_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/ble_scan_bloc/ble_scan_bloc.dart';
import '../blocs/ble_scan_bloc/ble_scan_state.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/app_loader.dart';
import '../widgets/empty_state.dart';
import 'ble_detail_screen.dart';

class BleScanScreen extends StatelessWidget {
  const BleScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'BLE Scanner',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          BlocBuilder<BleScanBloc, BleScanState>(
            builder: (context, state) {
              final isScanning = state.status == BleScanStatus.scanning;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isScanning
                        ? () => context.read<BleScanBloc>().stopScan()
                        : () => context.read<BleScanBloc>().startScan(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isScanning
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isScanning ? Icons.stop_circle : Icons.radar,
                            color: isScanning ? Colors.red[700] : Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isScanning ? 'Stop' : 'Scan',
                            style: TextStyle(
                              color: isScanning ? Colors.red[700] : Colors.blue[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<BleScanBloc, BleScanState>(
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BleScanState state) {
    final devices = state.devices;

    // ✅ When scanning or already have devices — show the list
    if (state.status == BleScanStatus.scanning || devices.isNotEmpty) {
      if (devices.isEmpty) {
        return const AppLoader(message: 'Scanning for devices...');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  '${devices.length} ${devices.length == 1 ? 'Device' : 'Devices'} Found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
                if (state.status == BleScanStatus.scanning)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[700]!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return DeviceListTile(
                  device: device,
                  onTap: () => _onDeviceTap(context, device),
                );
              },
            ),
          ),
        ],
      );
    }

    // ✅ Bluetooth off
    if (state.status == BleScanStatus.bluetoothOff) {
      return EmptyState(
        message: 'Bluetooth is off\nPlease enable Bluetooth to continue',
        icon: Icons.bluetooth_disabled,
      );
    }

    // ✅ Permission error
    if (state.status == BleScanStatus.permissionError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Permissions Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We need Bluetooth and location permissions to scan for nearby devices',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.read<BleScanBloc>().requestPermissions(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Grant Permissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Error state
    if (state.status == BleScanStatus.error) {
      return EmptyState(
        message: state.errorMessage ?? 'An error occurred',
        icon: Icons.error_outline,
      );
    }

    // ✅ Default "ready" state when no devices found
    return const EmptyState(
      message: 'Ready to scan\nTap scan to discover devices',
      icon: Icons.bluetooth_searching,
    );
  }

  void _onDeviceTap(BuildContext context, BleDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailScreen(device: device),
      ),
    );
  }
}