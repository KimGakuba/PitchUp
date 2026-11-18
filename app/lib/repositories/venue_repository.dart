import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/review.dart';
import '../models/venue.dart';

class VenueRepository {
  VenueRepository({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  }) : _db = db ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _venues =>
      _db.collection('venues');

  Stream<List<Venue>> watchVenues() {
    return _venues
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
          final venues = snap.docs
              .map((d) => Venue.fromMap(d.id, d.data()))
              .toList(growable: false);
          venues.sort((a, b) => b.rating.compareTo(a.rating));
          return venues;
        });
  }

  Stream<Venue?> watchVenue(String venueId) {
    return _venues.doc(venueId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Venue.fromMap(snap.id, snap.data() ?? const {});
    });
  }

  Stream<List<Venue>> watchOwnerVenues(String ownerId) {
    return _venues.where('ownerId', isEqualTo: ownerId).snapshots().map((snap) {
      final venues = snap.docs
          .map((d) => Venue.fromMap(d.id, d.data()))
          .toList(growable: false);
      venues.sort((a, b) => a.name.compareTo(b.name));
      return venues;
    });
  }

  Future<String> createVenue(Venue venue, String ownerId) async {
    final ref = _venues.doc();
    await ref.set(venue.toCreateMap(ownerId));
    return ref.id;
  }

  Future<void> updateVenue(Venue venue) {
    return _venues.doc(venue.id).update(venue.toUpdateMap());
  }

  Stream<List<Review>> watchReviews(String venueId) {
    return _db
        .collection('reviews')
        .where('venueId', isEqualTo: venueId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Review.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Future<void> addReview({
    required String venueId,
    required String userId,
    required String userName,
    required int rating,
    required String text,
  }) {
    return _db.collection('reviews').add({
      'venueId': venueId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'text': text.trim(),
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadVenuePhoto({
    required String venueId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final extension = contentType.split('/').last;
    final ref = _storage.ref(
      'venues/$venueId/${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
  }
}
