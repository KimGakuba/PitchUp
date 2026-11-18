enum BookingStatus { upcoming, completed, cancelled }

enum BookingPaymentStatus { pending, success, failed }

/// Mirrors `bookings/{bookingId}`. Created only via the `createBooking`
/// Cloud Function, which transactionally claims `venues/{id}/slots/*` docs
/// to guarantee no double-booking.
class Booking {
  final String id;
  final String ref; // PU-XXXX-XX
  final String venueId;
  final String userId;
  final DateTime date;
  final String startTime; // HH:mm
  final int durationMin; // 60 | 90 | 120
  final int totalPrice; // integer RWF
  final BookingStatus status;
  final BookingPaymentStatus paymentStatus;

  const Booking({
    required this.id,
    required this.ref,
    required this.venueId,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.durationMin,
    required this.totalPrice,
    this.status = BookingStatus.upcoming,
    this.paymentStatus = BookingPaymentStatus.pending,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    final rawDate = (map['date'] ?? '1970-01-01') as String;
    return Booking(
      id: id,
      ref: (map['ref'] ?? '') as String,
      venueId: (map['venueId'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      date: DateTime.tryParse(rawDate) ?? DateTime(1970),
      startTime: (map['startTime'] ?? '00:00') as String,
      durationMin: (map['durationMin'] as num?)?.toInt() ?? 60,
      totalPrice: (map['totalPrice'] as num?)?.toInt() ?? 0,
      status: BookingStatus.values.firstWhere(
        (s) => s.name == (map['status']?.toString() ?? 'upcoming'),
        orElse: () => BookingStatus.upcoming,
      ),
      paymentStatus: BookingPaymentStatus.values.firstWhere(
        (s) => s.name == (map['paymentStatus']?.toString() ?? 'pending'),
        orElse: () => BookingPaymentStatus.pending,
      ),
    );
  }

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  String get ymd =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime get kickoff {
    final parts = startTime.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime get endsAt => kickoff.add(Duration(minutes: durationMin));

  bool get isPast => endsAt.isBefore(DateTime.now());

  Booking copyWith({
    BookingStatus? status,
    BookingPaymentStatus? paymentStatus,
  }) {
    return Booking(
      id: id,
      ref: ref,
      venueId: venueId,
      userId: userId,
      date: date,
      startTime: startTime,
      durationMin: durationMin,
      totalPrice: totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
