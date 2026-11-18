import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../firebase_options_emulator.dart';
import 'config.dart';

/// Initialises Firebase and wires every product to the local Emulator Suite
/// when [AppConfig.useEmulator] is on.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: AppConfig.useEmulator
          ? EmulatorFirebaseOptions.currentPlatform
          : DefaultFirebaseOptions.currentPlatform,
    );
    if (!AppConfig.useEmulator) return;

    final host = AppConfig.emulatorHost;
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseStorage.instance.useStorageEmulator(host, 9199);
    FirebaseFunctions.instanceFor(
      region: AppConfig.functionsRegion,
    ).useFunctionsEmulator(host, 5001);

    debugPrint(
      'Firebase emulators: $host (project ${EmulatorFirebaseOptions.projectId})',
    );
  }
}
