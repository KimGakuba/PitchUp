class GameResult {
  final String gameId;
  final int scoreA;
  final int scoreB;
  final String postedBy;

  const GameResult({
    required this.gameId,
    required this.scoreA,
    required this.scoreB,
    required this.postedBy,
  });

  factory GameResult.fromMap(String gameId, Map<String, dynamic> map) {
    return GameResult(
      gameId: gameId,
      scoreA: (map['scoreA'] as num?)?.toInt() ?? 0,
      scoreB: (map['scoreB'] as num?)?.toInt() ?? 0,
      postedBy: (map['postedBy'] ?? '') as String,
    );
  }
}
