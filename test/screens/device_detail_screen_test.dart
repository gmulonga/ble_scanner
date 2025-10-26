import 'package:ble_scanner/screens/ble_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ble_scanner/blocs/ble_scan_bloc/ble_scan_bloc.dart';
import 'package:ble_scanner/models/ble_device_model.dart';

void main() {
  testWidgets('Displays device name and status correctly', (WidgetTester tester) async {
    final testDevice = BleDevice(
      id: '123',
      name: 'Test Device',
      serviceUuids: [],
      rssi: -65,
      isConnectable: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => BleScanBloc(),
          child: DeviceDetailScreen(device: testDevice),
        ),
      ),
    );

    // Verify the device name
    expect(find.text('Test Device'), findsOneWidget);

    // Verify status chip appears
    expect(find.text('Disconnected'), findsOneWidget);

    // Tap the connect button
    final connectButton = find.textContaining('Connect');
    expect(connectButton, findsOneWidget);
    await tester.tap(connectButton);
    await tester.pump();

    // Verify button updates after interaction
    expect(find.textContaining('Connecting'), findsOneWidget);
  });
}
