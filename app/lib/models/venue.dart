enum Sport { football, basketball }

extension SportLabel on Sport {
  String get label => switch (this) {
    Sport.football => 'Football',
    Sport.basketball => 'Basketball',
  };

  String get wireName => name;

  static Sport parse(Object? value) {
    final raw = value?.toString().toLowerCase();
    return Sport.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => Sport.football,
    );
  }
}

enum KigaliSector { all, remera, nyarutarama, kicukiro, kimihurura, nyamirambo }

extension KigaliSectorLabel on KigaliSector {
  String get label => switch (this) {
    KigaliSector.all => 'All',
    KigaliSector.remera => 'Remera',
    KigaliSector.nyarutarama => 'Nyarutarama',
    KigaliSector.kicukiro => 'Kicukiro',
    KigaliSector.kimihurura => 'Kimihurura',
    KigaliSector.nyamirambo => 'Nyamirambo',
  };

  static KigaliSector parse(Object? value) {
    final raw = value?.toString().toLowerCase();
    return KigaliSector.values.firstWhere(
      (s) => s.label.toLowerCase() == raw || s.name == raw,
      orElse: () => KigaliSector.all,
    );
  }
}

enum VenueStatus { active, inactive, pending }

/// Mirrors `venues/{venueId}`. `pricePerHour` and all money fields across
/// the app are integer RWF — never a double — per the project's currency rule.
class Venue {
  final String id;
  final String ownerId;
  final String name;
  final Sport sport;
  final String format; // e.g. "7-a-side", "full-court", "3x3"
  final String surface;
  final KigaliSector sector;
  final String address;
  final int pricePerHour;
  final List<String> amenities;
  final List<String> photos;
  final double rating;
  final int ratingCount;
  final VenueStatus status;

  const Venue({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.sport,
    required this.format,
    required this.surface,
    required this.sector,
    required this.address,
    required this.pricePerHour,
    this.amenities = const [],
    this.photos = const [],
    this.rating = 0,
    this.ratingCount = 0,
    this.status = VenueStatus.active,
  });

  factory Venue.fromMap(String id, Map<String, dynamic> map) {
    return Venue(
      id: id,
      ownerId: (map['ownerId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      sport: SportLabel.parse(map['sport']),
      format: (map['format'] ?? '') as String,
      surface: (map['surface'] ?? '') as String,
      sector: KigaliSectorLabel.parse(map['sector']),
      address: (map['address'] ?? '') as String,
      pricePerHour: (map['pricePerHour'] as num?)?.toInt() ?? 0,
      amenities: (map['amenities'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      photos: (map['photos'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      status: VenueStatus.values.firstWhere(
        (s) => s.name == (map['status']?.toString() ?? 'active'),
        orElse: () => VenueStatus.active,
      ),
    );
  }

  /// Payload for an owner-created venue. The aggregated rating fields start
  /// at zero and are only ever changed by the review trigger.
  Map<String, dynamic> toCreateMap(String ownerId) => {
    'ownerId': ownerId,
    'name': name,
    'sport': sport.wireName,
    'format': format,
    'surface': surface,
    'sector': sector.label,
    'address': address,
    'geo': const {'lat': -1.9441, 'lng': 30.0619},
    'pricePerHour': pricePerHour,
    'amenities': amenities,
    'photos': photos,
    'rating': 0,
    'ratingCount': 0,
    'status': 'active',
  };

  Map<String, dynamic> toUpdateMap() => {
    'name': name,
    'sport': sport.wireName,
    'format': format,
    'surface': surface,
    'sector': sector.label,
    'address': address,
    'pricePerHour': pricePerHour,
    'amenities': amenities,
    'photos': photos,
    'status': status.name,
  };
}
