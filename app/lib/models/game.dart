import 'venue.dart';

enum GameStatus { open, full, completed, cancelled }

enum Attendance { present, excused, noShow, none }

extension AttendanceWire on Attendance {
  String? get wireName => switch (this) {
    Attendance.present => 'present',
    Attendance.excused => 'excused',
    Attendance.noShow => 'no_show',
    Attendance.none => null,
  };

  String get label => switch (this) {
    Attendance.present => 'Present',
    Attendance.excused => 'Excused',
    Attendance.noShow => 'No-show',
    Attendance.none => 'Unmarked',
  };

  static Attendance parse(Object? value) {
    return switch (value?.toString()) {
      'present' => Attendance.present,
      'excused' => Attendance.excused,
      'no_show' => Attendance.noShow,
      _ => Attendance.none,
    };
  }
}

/// Mirrors `games/{gameId}`. `costPerPlayer` is recomputed by the
/// `joinGame`/`leaveGame` Cloud Functions as
/// `ceil(totalPrice / confirmedPlayers)` — the rounding remainder is
/// absorbed by the organizer's share.
class Game {
  final String id;
  final String bookingId;
  final String venueId;
  final String organizerId;
  final String title;
  final Sport sport;
  final int maxPlayers;
  final int costPerPlayer;
  final List<String> playerIds;
  final List<String> teamA;
  final List<String> teamB;
  final GameStatus status;
  final DateTime kickoff;

  const Game({
    required this.id,
    required this.bookingId,
    required this.venueId,
    required this.organizerId,
    required this.title,
    required this.sport,
    required this.maxPlayers,
    required this.costPerPlayer,
    required this.kickoff,
    this.playerIds = const [],
    this.teamA = const [],
    this.teamB = const [],
    this.status = GameStatus.open,
  });

  factory Game.fromMap(
    String id,
    Map<String, dynamic> map, {
    required DateTime kickoff,
  }) {
    return Game(
      id: id,
      bookingId: (map['bookingId'] ?? '') as String,
      venueId: (map['venueId'] ?? '') as String,
      organizerId: (map['organizerId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      sport: SportLabel.parse(map['sport']),
      maxPlayers: (map['maxPlayers'] as num?)?.toInt() ?? 0,
      costPerPlayer: (map['costPerPlayer'] as num?)?.toInt() ?? 0,
      playerIds: (map['playerIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      teamA: (map['teamA'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      teamB: (map['teamB'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      status: GameStatus.values.firstWhere(
        (s) => s.name == (map['status']?.toString() ?? 'open'),
        orElse: () => GameStatus.open,
      ),
      kickoff: kickoff,
    );
  }

  int get confirmedPlayers => playerIds.length;

  bool get isFull => confirmedPlayers >= maxPlayers;

  Game copyWith({
    int? costPerPlayer,
    List<String>? playerIds,
    GameStatus? status,
    List<String>? teamA,
    List<String>? teamB,
  }) {
    return Game(
      id: id,
      bookingId: bookingId,
      venueId: venueId,
      organizerId: organizerId,
      title: title,
      sport: sport,
      maxPlayers: maxPlayers,
      costPerPlayer: costPerPlayer ?? this.costPerPlayer,
      kickoff: kickoff,
      playerIds: playerIds ?? this.playerIds,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      status: status ?? this.status,
    );
  }
}

/// A game plus the booking/venue context the UI needs. Firestore keeps the
/// game document lean (per the agreed data model); kickoff and price live on
/// the linked booking.
class GameWithContext {
  final Game game;
  final BookingSummary booking;

  const GameWithContext({required this.game, required this.booking});
}

class BookingSummary {
  final String id;
  final String ref;
  final String venueId;
  final String date;
  final String startTime;
  final int durationMin;
  final int totalPrice;
  final Venue venue;

  const BookingSummary({
    required this.id,
    required this.ref,
    required this.venueId,
    required this.date,
    required this.startTime,
    required this.durationMin,
    required this.totalPrice,
    required this.venue,
  });
}

class RosterPlayer {
  final String uid;
  final String? name;
  final String? position;
  final double reliabilityScore;
  final int gamesPlayed;
  final bool paid;
  final Attendance attendance;
  final DateTime? joinedAt;

  const RosterPlayer({
    required this.uid,
    this.name,
    this.position,
    this.reliabilityScore = 100,
    this.gamesPlayed = 0,
    this.paid = false,
    this.attendance = Attendance.none,
    this.joinedAt,
  });
}
