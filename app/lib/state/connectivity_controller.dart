import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityController extends ChangeNotifier {
  ConnectivityController({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _offline = false;
  bool get offline => _offline;

  Future<void> start() async {
    _update(await _connectivity.checkConnectivity());
    _sub ??= _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (offline == _offline) return;
    _offline = offline;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
