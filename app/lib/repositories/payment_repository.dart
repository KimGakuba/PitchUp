import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment.dart';
import '../services/functions_api.dart';

class PaymentRepository {
  PaymentRepository({
    FirebaseFirestore? db,
    FunctionsApi? functions,
  }) : _db = db ?? FirebaseFirestore.instance,
       _functions = functions ?? FunctionsApi();

  final FirebaseFirestore _db;
  final FunctionsApi _functions;

  Future<InitiatedPayment> initiate({
    required String purpose, // game | booking
    required String targetId,
    required PaymentProvider provider,
    required String phone,
  }) async {
    final data = await _functions.call('initiatePayment', {
      'purpose': purpose,
      'targetId': targetId,
      'provider': provider.wireName,
      'phone': phone,
    });
    return InitiatedPayment(
      paymentId: data['paymentId'] as String? ?? '',
      providerRef: data['providerRef'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      message: data['message'] as String? ?? '',
    );
  }

  Future<void> simulateOutcome(String paymentId, {required bool success}) async {
    await _functions.call('simulatePaymentOutcome', {
      'paymentId': paymentId,
      'outcome': success ? 'success' : 'failed',
    });
  }

  Stream<Payment?> watchPayment(String paymentId) {
    return _db.collection('payments').doc(paymentId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Payment.fromMap(snap.id, snap.data() ?? const {});
    });
  }

  /// Payments for one game + player, newest first (customer side).
  Stream<List<Payment>> watchGamePayments(String gameId, String userId) {
    return _db
        .collection('payments')
        .where('gameId', isEqualTo: gameId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final payments = snap.docs
              .map((d) => Payment.fromMap(d.id, d.data()))
              .toList(growable: false);
          payments.sort((a, b) => b.id.compareTo(a.id));
          return payments;
        });
  }

  Stream<List<Payment>> watchBookingPayments(String bookingId) {
    return _db
        .collection('payments')
        .where('bookingId', isEqualTo: bookingId)
        .snapshots()
        .map((snap) {
          final payments = snap.docs
              .map((d) => Payment.fromMap(d.id, d.data()))
              .toList(growable: false);
          payments.sort((a, b) => b.id.compareTo(a.id));
          return payments;
        });
  }
}

class InitiatedPayment {
  const InitiatedPayment({
    required this.paymentId,
    required this.providerRef,
    required this.amount,
    required this.message,
  });

  final String paymentId;
  final String providerRef;
  final int amount;
  final String message;
}
