import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/report.dart';
import '../services/functions_api.dart';

class AdminRepository {
  AdminRepository({
    FirebaseFirestore? db,
    FunctionsApi? functions,
  }) : _db = db ?? FirebaseFirestore.instance,
       _functions = functions ?? FunctionsApi();

  final FirebaseFirestore _db;
  final FunctionsApi _functions;

  Stream<List<UserReport>> watchReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => UserReport.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Future<void> setUserStatus(
    String uid, {
    required bool suspend,
    String? reason,
  }) async {
    await _functions.call('setUserStatus', {
      'uid': uid,
      'suspend': suspend,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<void> setUserRole(String uid, String role) async {
    await _functions.call('setUserRole', {'uid': uid, 'role': role});
  }

  Future<void> resolveReport(
    String reportId, {
    required String action,
    String? notes,
  }) async {
    await _functions.call('resolveReport', {
      'reportId': reportId,
      'action': action,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }
}
