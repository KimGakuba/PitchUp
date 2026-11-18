import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/game.dart';
import '../models/result.dart';
import '../models/user_profile.dart';
import '../models/venue.dart';
import '../services/functions_api.dart';
import 'user_repository.dart';

class GameRepository {
  GameRepository({
    FirebaseFirestore? db,
    FunctionsApi? functions,
    UserRepository? users,
  }) : _db = db ?? FirebaseFirestore.instance,
       _functions = functions ?? FunctionsApi(),
       _users = users ?? UserRepository();

  final FirebaseFirestore _db;
  final FunctionsApi _functions;
  final UserRepository _users;

  CollectionReference<Map<String, dynamic>> get _games => _db.collection('games');

  Stream<List<GameWithContext>> watchOpenGames() {
    return _games
        .where('status', whereIn: ['open', 'full'])
        .snapshots()
        .asyncMap(_mapGames);
  }

  Stream<List<GameWithContext>> watchAllGames() {
    return _games.orderBy('createdAt', descending: true).snapshots().asyncMap(
      _mapGames,
    );
  }

  Stream<GameWithContext?> watchGame(String gameId) {
    return _games.doc(gameId).snapshots().asyncMap((snap) async {
      if (!snap.exists) return null;
      final context = await _mapGame(snap.id, snap.data() ?? const {});
      return context;
    });
  }

  Future<GameWithContext?> getGame(String gameId) async {
    final snap = await _games.doc(gameId).get();
    if (!snap.exists) return null;
    return _mapGame(snap.id, snap.data() ?? const {});
  }

  Stream<List<RosterPlayer>> watchRoster(String gameId) {
    return _games.doc(gameId).collection('players').snapshots().asyncMap((
      snap,
    ) async {
      final users = await _users.getUsers(snap.docs.map((d) => d.id));
      final byId = {for (final u in users) u.uid: u};
      final roster = snap.docs.map((doc) {
        final data = doc.data();
        final user = byId[doc.id];
        final rawJoined = data['joinedAt'];
        return RosterPlayer(
          uid: doc.id,
          name: user?.name,
          position: user?.position,
          reliabilityScore: user?.reliabilityScore ?? 100,
          gamesPlayed: user?.gamesPlayed ?? 0,
          paid: data['paymentStatus'] == 'paid',
          attendance: AttendanceWire.parse(data['attendance']),
          joinedAt: rawJoined is Timestamp ? rawJoined.toDate() : null,
        );
      }).toList(growable: false);
      roster.sort((a, b) {
        final at = a.joinedAt ?? DateTime(1970);
        final bt = b.joinedAt ?? DateTime(1970);
        return at.compareTo(bt);
      });
      return roster;
    });
  }

  Stream<GameResult?> watchResult(String gameId) {
    return _db.collection('results').doc(gameId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return GameResult.fromMap(snap.id, snap.data() ?? const {});
    });
  }

  Future<JoinResult> joinGame(String gameId) async {
    final data = await _functions.call('joinGame', {'gameId': gameId});
    return JoinResult(
      alreadyJoined: data['alreadyJoined'] == true,
      costPerPlayer: (data['costPerPlayer'] as num?)?.toInt() ?? 0,
    );
  }

  Future<LeaveResult> leaveGame(String gameId) async {
    final data = await _functions.call('leaveGame', {'gameId': gameId});
    return LeaveResult(
      costPerPlayer: (data['costPerPlayer'] as num?)?.toInt() ?? 0,
      confirmedPlayers: (data['confirmedPlayers'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> setTeams(
    String gameId,
    List<String> teamA,
    List<String> teamB,
  ) async {
    await _functions.call('setTeams', {
      'gameId': gameId,
      'teamA': teamA,
      'teamB': teamB,
    });
  }

  Future<void> markAttendance(
    String gameId,
    Map<String, String> attendance,
  ) async {
    await _functions.call('markAttendance', {
      'gameId': gameId,
      'attendance': attendance,
    });
  }

  Future<void> postResult(String gameId, int scoreA, int scoreB) async {
    await _functions.call('postResult', {
      'gameId': gameId,
      'scoreA': scoreA,
      'scoreB': scoreB,
    });
  }

  Future<List<GameWithContext>> _mapGames(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    final games = await Future.wait(
      snap.docs.map((doc) => _mapGame(doc.id, doc.data())),
    );
    final present = games.whereType<GameWithContext>().toList(growable: false);
    present.sort((a, b) => a.game.kickoff.compareTo(b.game.kickoff));
    return present;
  }

  Future<GameWithContext?> _mapGame(
    String id,
    Map<String, dynamic> data,
  ) async {
    final bookingId = data['bookingId'] as String?;
    final venueId = data['venueId'] as String?;
    if (bookingId == null || venueId == null) return null;
    final bookingSnap = await _db.collection('bookings').doc(bookingId).get();
    final venueSnap = await _db.collection('venues').doc(venueId).get();
    if (!bookingSnap.exists || !venueSnap.exists) return null;
    final booking = Booking.fromMap(
      bookingSnap.id,
      bookingSnap.data() ?? const {},
    );
    final venue = Venue.fromMap(venueSnap.id, venueSnap.data() ?? const {});
    final game = Game.fromMap(id, data, kickoff: booking.kickoff);
    return GameWithContext(
      game: game,
      booking: BookingSummary(
        id: booking.id,
        ref: booking.ref,
        venueId: booking.venueId,
        date: booking.ymd,
        startTime: booking.startTime,
        durationMin: booking.durationMin,
        totalPrice: booking.totalPrice,
        venue: venue,
      ),
    );
  }
}

class JoinResult {
  const JoinResult({required this.alreadyJoined, required this.costPerPlayer});
  final bool alreadyJoined;
  final int costPerPlayer;
}

class LeaveResult {
  const LeaveResult({
    required this.costPerPlayer,
    required this.confirmedPlayers,
  });
  final int costPerPlayer;
  final int confirmedPlayers;
}

extension RosterLeader on List<RosterPlayer> {
  RosterPlayer? get organizer => isEmpty ? null : first;
  double get averageReliability => isEmpty
      ? 100
      : fold<double>(0, (total, p) => total + p.reliabilityScore) / length;
}

UserProfile? profileFor(List<UserProfile> profiles, String uid) {
  for (final profile in profiles) {
    if (profile.uid == uid) return profile;
  }
  return null;
}
