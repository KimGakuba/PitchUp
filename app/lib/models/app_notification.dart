import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['createdAt'];
    return AppNotification(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      read: map['read'] == true,
      createdAt: raw is Timestamp ? raw.toDate() : DateTime.now(),
    );
  }
}
