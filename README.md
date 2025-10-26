# 🛰️ Flutter BLE Scanner

A simple Bluetooth Low Energy (BLE) scanning and device management app built with **Flutter** and **BLoC state management**.  
It allows users to:
- Scan for nearby BLE devices
- Connect and disconnect to devices
- View signal strength (RSSI) dynamically
- Discover services and characteristics
- Display service UUIDs and their properties (Read, Write, Notify)

---

## 📱 Features

✅ Bluetooth scan with auto-stop timer  
✅ Permission handling (Bluetooth & Location)  
✅ Real-time RSSI updates  
✅ Service and characteristic discovery  
✅ Device connection management  
✅ Clean architecture using BLoC pattern

---

## 🛠️ Tech Stack

| Component            | Description |
|----------------------|------------|
| **Flutter**          | 3.32.2 (Stable) |
| **Dart**             | 3.8.1 |
| **State Management** | flutter_bloc |
| **Bluetooth**        | flutter_blue_plus |
| **Permissions**      | permission_handler |
| **UI Toolkit**       | Material Design |
| **Location**         | geolocator |

---

## 🧩 State Management Choice — Why BLoC?

This project uses BLoC (Business Logic Component) for state management because it provides a structured, testable, and scalable way to separate UI from business logic.

💡 Why BLoC?

 - Separation of concerns: BLoC enforces a clear separation between presentation (UI) and logic (events and state), making the app easier to maintain and extend.

 - Predictable state flow: Data flows in one direction — events trigger state changes, and states update the UI. This makes debugging and reasoning about the app behavior much easier.

 - Reusability: Business logic components can be reused across different widgets and screens without UI dependencies.

 - Testability: Because logic is isolated from widgets, writing unit and widget tests becomes straightforward.

 - Scalability: As the app grows, BLoC’s structure ensures that complex features remain organized and consistent.

--- 

## ⚙️ Setup Instructions

### 1️⃣ Prerequisites
Before you begin, make sure you have:
- [Flutter SDK 3.32.2+](https://docs.flutter.dev/get-started/install)
- Android Studio or Xcode installed
- A physical device (BLE doesn’t work properly on most emulators)
- Bluetooth and Location permissions enabled

---

### 2️⃣ Clone the Repository

```bash
git clone https://github.com/gmulonga/ble_scanner.git
cd ble_scanner
```

### Install Dependencies
```bash
flutter pub get
```

### Configure IOS permisions
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to discover and connect to nearby devices.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app requires Bluetooth access to communicate with devices.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required to detect nearby Bluetooth devices.</string>

```

### Configure Android permisions
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

```

### Project Structure
```css
lib/
├── blocs/
│   └── ble_scan_bloc/
│       ├── ble_scan_bloc.dart
│       ├── ble_scan_state.dart
├── models/
│   └── ble_device_model.dart
├── repositories/
│   └── ble_repository.dart
├── utils/
│   └── permission_helper.dart
│   └── constants.dart
├── widgets/
│   ├── app_loader.dart
│   ├── custom_snackbar.dart
│   ├── device_list.dart
│   ├── empty_state.dart
├── screens/
│   ├── ble_detail_screen.dart
│   ├── ble_scan_screen.dart
└── main.dart
└── app.dart

```


### Run the app
```bash
flutter run
```