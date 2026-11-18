import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors `reviews/{reviewId}`. `verified` is set true only when the
/// reviewer has a completed booking at the venue (enforced server-side).
class Review {
  final String id;
  final String venueId;
  final String userId;
  final String userName;
  final int rating; // 1-5
  final String text;
  final bool verified;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.text,
    this.verified = false,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    final rawCreated = map['createdAt'];
    final createdAt = rawCreated is Timestamp
        ? rawCreated.toDate()
        : DateTime.tryParse(rawCreated?.toString() ?? '') ?? DateTime.now();
    return Review(
      id: id,
      venueId: (map['venueId'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? 'Player') as String,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      text: (map['text'] ?? '') as String,
      verified: map['verified'] == true,
      createdAt: createdAt,
    );
  }
}
