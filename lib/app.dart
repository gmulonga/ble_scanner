import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/ble_scan_bloc/ble_scan_bloc.dart';
import 'screens/ble_scan_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BleScanBloc()),
      ],
      child: MaterialApp(
        title: 'BLE Scanner',
        home: const BleScanScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}