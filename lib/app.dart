import 'package:ble_scanner/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'blocs/ble_scan_bloc/ble_scan_bloc.dart';
import 'screens/ble_scan_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  String _statusMessage = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detect when user comes back from settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When the user returns to the app from settings
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Checking permissions...';
        _hasError = false;
      });

      final hasPermissions = await PermissionHelper.requestBluetoothPermissions();
      if (!hasPermissions) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage = 'Bluetooth and Location permissions are required.';
        });
        return;
      }

      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage = 'Please enable Location services to continue.';
        });

        await Geolocator.openLocationSettings();
        return;
      }

      final bluetoothState = await FlutterBluePlus.adapterState.first;
      if (bluetoothState != BluetoothAdapterState.on) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage = 'Please turn ON Bluetooth to continue.';
        });

        await FlutterBluePlus.turnOn();
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'Error initializing: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BleScanBloc()),
      ],
      child: MaterialApp(
        title: 'BLE Scanner',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: _isLoading
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            )
                : const BleScanScreen(),
          ),
        ),
      ),
    );
  }
}
