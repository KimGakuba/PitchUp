import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/slot.dart';
import '../services/functions_api.dart';

class BookingRepository {
  BookingRepository({
    FirebaseFirestore? db,
    FunctionsApi? functions,
  }) : _db = db ?? FirebaseFirestore.instance,
       _functions = functions ?? FunctionsApi();

  final FirebaseFirestore _db;
  final FunctionsApi _functions;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  Stream<List<Booking>> watchMyBookings(String userId) {
    return _bookings
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Booking.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Stream<Booking?> watchBooking(String bookingId) {
    return _bookings.doc(bookingId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Booking.fromMap(snap.id, snap.data() ?? const {});
    });
  }

  Stream<List<Booking>> watchOwnerBookings(List<String> venueIds) {
    if (venueIds.isEmpty) return Stream.value(const []);
    final selected = venueIds.take(30).toList(growable: false);
    return _bookings
        .where('venueId', whereIn: selected)
        .snapshots()
        .map((snap) {
          final bookings = snap.docs
              .map((d) => Booking.fromMap(d.id, d.data()))
              .toList(growable: false);
          bookings.sort((a, b) => b.kickoff.compareTo(a.kickoff));
          return bookings;
        });
  }

  Stream<Booking?> watchGameBooking(String bookingId) =>
      watchBooking(bookingId);

  /// Admin overview. Reading every booking is allowed for admins by the
  /// security rules; cap the stream so the dashboard stays responsive.
  Stream<List<Booking>> watchAllBookings({int limit = 500}) {
    return _bookings
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Booking.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  /// Real-time occupancy for one Kigali calendar day. Only the 30-minute
  /// documents for that date are read (document-ID range query).
  Stream<Map<String, VenueSlot>> watchDaySlots(
    String venueId,
    String dateKey,
  ) {
    return _db
        .collection('venues')
        .doc(venueId)
        .collection('slots')
        .where(
          FieldPath.documentId,
          isGreaterThanOrEqualTo: '${dateKey}_',
          isLessThan: '${dateKey}_\uf8ff',
        )
        .snapshots()
        .map(
          (snap) => {
            for (final doc in snap.docs)
              doc.id: VenueSlot.fromMap(doc.id, doc.data()),
          },
        );
  }

  Stream<List<VenueSlot>> watchAllDaySlots(String venueId, String dateKey) {
    return watchDaySlots(venueId, dateKey).map((map) => map.values.toList());
  }

  Future<CreateBookingResult> createBooking({
    required String venueId,
    required String date,
    required String startTime,
    required int durationMin,
  }) async {
    final data = await _functions.call('createBooking', {
      'venueId': venueId,
      'date': date,
      'startTime': startTime,
      'durationMin': durationMin,
    });
    return CreateBookingResult(
      bookingId: data['bookingId'] as String? ?? '',
      ref: data['ref'] as String? ?? '',
      totalPrice: (data['totalPrice'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await _functions.call('cancelBooking', {
      'bookingId': bookingId,
      'reason': ?reason,
    });
  }

  Future<String> convertToGame({
    required String bookingId,
    required String title,
    required int maxPlayers,
  }) async {
    final data = await _functions.call('convertToGame', {
      'bookingId': bookingId,
      'title': title,
      'maxPlayers': maxPlayers,
    });
    return data['gameId'] as String? ?? '';
  }

  Future<SetSlotBlockedResult> setSlotBlocked({
    required String venueId,
    required String date,
    required List<String> slotIds,
    required bool blocked,
    String? reason,
  }) async {
    final data = await _functions.call('setSlotBlocked', {
      'venueId': venueId,
      'date': date,
      'slotIds': slotIds,
      'blocked': blocked,
      'reason': ?reason,
    });
    return SetSlotBlockedResult(
      changed: (data['changed'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}

class CreateBookingResult {
  const CreateBookingResult({
    required this.bookingId,
    required this.ref,
    required this.totalPrice,
  });

  final String bookingId;
  final String ref;
  final int totalPrice;
}

class SetSlotBlockedResult {
  const SetSlotBlockedResult({required this.changed, required this.skipped});

  final int changed;
  final List<String> skipped;
}
