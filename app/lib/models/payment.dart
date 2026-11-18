enum PaymentProvider { mtn, airtel }

extension PaymentProviderLabel on PaymentProvider {
  String get label => switch (this) {
    PaymentProvider.mtn => 'MTN MoMo',
    PaymentProvider.airtel => 'Airtel Money',
  };

  String get wireName => name;

  static PaymentProvider parse(Object? value) {
    return PaymentProvider.values.firstWhere(
      (p) => p.name == value?.toString(),
      orElse: () => PaymentProvider.mtn,
    );
  }
}

enum PaymentState { pending, success, failed }

/// Mirrors `payments/{paymentId}`. Created server-side only by the
/// `initiatePayment` Cloud Function — never written by the client.
class Payment {
  final String id;
  final String? gameId;
  final String? bookingId;
  final String userId;
  final int amount; // integer RWF
  final PaymentProvider provider;
  final String phone;
  final PaymentState status;
  final String? providerRef;

  const Payment({
    required this.id,
    this.gameId,
    this.bookingId,
    required this.userId,
    required this.amount,
    required this.provider,
    required this.phone,
    this.status = PaymentState.pending,
    this.providerRef,
  });

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      gameId: map['gameId'] as String?,
      bookingId: map['bookingId'] as String?,
      userId: (map['userId'] ?? '') as String,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      provider: PaymentProviderLabel.parse(map['provider']),
      phone: (map['phone'] ?? '') as String,
      status: PaymentState.values.firstWhere(
        (s) => s.name == (map['status']?.toString() ?? 'pending'),
        orElse: () => PaymentState.pending,
      ),
      providerRef: map['providerRef'] as String?,
    );
  }
}
