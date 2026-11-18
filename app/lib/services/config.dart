import 'package:flutter/foundation.dart';

/// Runtime configuration for local emulators vs. deployed Firebase.
class AppConfig {
  AppConfig._();

  static const String functionsRegion = 'europe-west1';

  /// `flutter run --dart-define=USE_FIREBASE_EMULATOR=false` to hit the cloud.
  static const bool useEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: kDebugMode,
  );

  /// Override for physical devices, e.g.
  /// `--dart-define=FIREBASE_EMULATOR_HOST=192.168.1.20`.
  static const String _hostOverride = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
  );

  static String get emulatorHost {
    if (_hostOverride.isNotEmpty) return _hostOverride;
    if (kIsWeb) return 'localhost';
    // Android emulators reach the host machine through 10.0.2.2.
    return defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
  }
}
