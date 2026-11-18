import 'package:flutter/material.dart';

import 'app.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? initError;
  try {
    await FirebaseBootstrap.initialize();
  } catch (error) {
    initError = error;
  }
  runApp(PitchUpApp(initError: initError));
}
