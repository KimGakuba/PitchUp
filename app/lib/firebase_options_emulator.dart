import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Dummy client config used ONLY when talking to the local Emulator Suite.
///
/// The project id must stay `demo-*` so Firebase never contacts production
/// services even if an emulator is missing. Real cloud builds use the
/// FlutterFire-generated [DefaultFirebaseOptions] instead (see
/// `firebase_options.dart`).
class EmulatorFirebaseOptions {
  EmulatorFirebaseOptions._();

  static const projectId = 'demo-pitchup';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.android:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static const android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:android:pitchupdemo',
    messagingSenderId: '1234567890',
    projectId: projectId,
    storageBucket: 'demo-pitchup.appspot.com',
  );

  static const ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:ios:pitchupdemo',
    messagingSenderId: '1234567890',
    projectId: projectId,
    storageBucket: 'demo-pitchup.appspot.com',
    iosBundleId: 'com.pitchup.pitchup',
  );

  static const macos = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:macos:pitchupdemo',
    messagingSenderId: '1234567890',
    projectId: projectId,
    storageBucket: 'demo-pitchup.appspot.com',
    iosBundleId: 'com.pitchup.pitchup',
  );

  static const web = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:web:pitchupdemo',
    messagingSenderId: '1234567890',
    projectId: projectId,
    authDomain: 'demo-pitchup.firebaseapp.com',
    storageBucket: 'demo-pitchup.appspot.com',
  );
}
