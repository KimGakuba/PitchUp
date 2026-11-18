enum SlotStatus { booked, blocked }

/// Mirrors `venues/{venueId}/slots/{YYYYMMDD_HHmm}`. Presence means the
/// 30-minute block is unavailable.
class VenueSlot {
  final String id;
  final SlotStatus status;
  final String? bookingId;
  final String? reason;

  const VenueSlot({
    required this.id,
    required this.status,
    this.bookingId,
    this.reason,
  });

  factory VenueSlot.fromMap(String id, Map<String, dynamic> map) {
    return VenueSlot(
      id: id,
      status: SlotStatus.values.firstWhere(
        (s) => s.name == (map['status']?.toString() ?? 'booked'),
        orElse: () => SlotStatus.booked,
      ),
      bookingId: map['bookingId'] as String?,
      reason: map['reason'] as String?,
    );
  }

  bool get isBooked => status == SlotStatus.booked;
  bool get isBlocked => status == SlotStatus.blocked;
}
