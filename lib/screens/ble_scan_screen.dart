import 'package:ble_scanner/models/ble_device_model.dart';
import 'package:ble_scanner/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../blocs/ble_scan_bloc/ble_scan_bloc.dart';
import '../blocs/ble_scan_bloc/ble_scan_state.dart';
import '../utils/constants.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/app_loader.dart';
import '../widgets/empty_state.dart';
import 'ble_detail_screen.dart';

class BleScanScreen extends StatelessWidget {
  const BleScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleScanBloc, BleScanState>(
      builder: (context, state) {
        final isScanning = state.status == BleScanStatus.scanning;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: kWhite,
            centerTitle: true,
            title: const Text(
              'BLE Scanner',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
          body: _buildBody(context, state),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _handleScanToggle(context, isScanning),
                icon: Icon(
                  isScanning ? Icons.stop_circle : Icons.radar,
                  color: kWhite,
                ),
                label: Text(
                  isScanning ? 'Stop Scan' : 'Start Scan',
                  style: const TextStyle(
                    color: kWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isScanning ? kRed : kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleScanToggle(BuildContext context, bool isScanning) async {
    if (isScanning) {
      context.read<BleScanBloc>().stopScan();
      return;
    }

    final hasPermissions = await PermissionHelper.requestBluetoothPermissions();
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bluetooth and Location permissions are required.'),
          backgroundColor: kPrimary,
        ),
      );
      return;
    }

    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Enable Location'),
          content: const Text(
            'Location services are required to scan for BLE devices.\nWould you like to enable them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await Geolocator.openLocationSettings();
      }
      return;
    }

    context.read<BleScanBloc>().startScan();
  }

  Widget _buildBody(BuildContext context, BleScanState state) {
    final devices = state.devices;

    if (state.status == BleScanStatus.scanning || devices.isNotEmpty) {
      if (devices.isEmpty) {
        return const AppLoader(message: 'Scanning for devices...');
      }

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.devices, color: Colors.blue[700], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '${devices.length} ${devices.length == 1 ? 'Device' : 'Devices'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (state.status == BleScanStatus.scanning)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: kPrimary,
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10),
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

    if (state.status == BleScanStatus.bluetoothOff) {
      return EmptyState(
        message: 'Bluetooth is off\nPlease enable Bluetooth to continue',
        icon: Icons.bluetooth_disabled,
      );
    }

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
                child: Icon(Icons.lock_outline, size: 40, color: Colors.orange[700]),
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
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.read<BleScanBloc>().requestPermissions(),
                icon: const Icon(Icons.lock_open),
                label: const Text('Grant Permissions'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.status == BleScanStatus.error) {
      return EmptyState(
        message: state.errorMessage ?? 'An error occurred',
        icon: Icons.error_outline,
      );
    }

    return const EmptyState(
      message: 'Ready to scan\nTap scan to discover devices',
      icon: Icons.bluetooth_searching,
    );
  }

  void _onDeviceTap(BuildContext context, BleDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceDetailScreen(device: device)),
    );
  }
}