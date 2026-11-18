import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/app_notification.dart';
import '../services/functions_api.dart';

class NotificationRepository {
  NotificationRepository({
    FirebaseFirestore? db,
    FunctionsApi? functions,
  }) : _db = db ?? FirebaseFirestore.instance,
       _functions = functions ?? FunctionsApi();

  final FirebaseFirestore _db;
  final FunctionsApi _functions;

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Future<void> markRead(String notificationId) {
    return _db.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> registerDevice() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _functions.call('registerFcmToken', {'token': token});
    } catch (_) {
      // Push is best-effort; the app must still work without permission.
    }
  }

  Future<void> unregisterDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _functions.call('unregisterFcmToken', {'token': token});
    } catch (_) {
      // Ignore: sign-out should never be blocked by push cleanup.
    }
  }
}
