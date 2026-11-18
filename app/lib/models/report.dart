import 'package:cloud_firestore/cloud_firestore.dart';

class UserReport {
  final String id;
  final String reporterId;
  final String targetId;
  final String reason;
  final String status;
  final DateTime createdAt;

  const UserReport({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory UserReport.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['createdAt'];
    return UserReport(
      id: id,
      reporterId: (map['reporterId'] ?? '') as String,
      targetId: (map['targetId'] ?? '') as String,
      reason: (map['reason'] ?? '') as String,
      status: (map['status'] ?? 'open') as String,
      createdAt: raw is Timestamp ? raw.toDate() : DateTime.now(),
    );
  }
}
