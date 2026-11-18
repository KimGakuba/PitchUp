import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../models/venue.dart';
import '../../repositories/venue_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';
import 'date_time_selection_screen.dart';
import 'reviews_screen.dart';

class PitchDetailsScreen extends StatelessWidget {
  const PitchDetailsScreen({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<VenueRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pitch details')),
      body: AsyncStreamView<Venue?>(
        stream: repository.watchVenue(venueId),
        loadingMessage: 'Loading pitch…',
        builder: (context, venue) {
          if (venue == null) {
            return const EmptyView(
              icon: Icons.location_off_outlined,
              title: 'Pitch unavailable',
              message: 'This pitch may have been removed by its owner.',
            );
          }
          return AsyncStreamView<List<Review>>(
            stream: repository.watchReviews(venueId),
            loadingMessage: 'Loading reviews…',
            builder: (context, reviews) => _VenueDetails(
              venue: venue,
              reviews: reviews,
            ),
          );
        },
      ),
    );
  }
}

class _VenueDetails extends StatelessWidget {
  const _VenueDetails({required this.venue, required this.reviews});

  final Venue venue;
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            _HeroImage(venue: venue),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: const TextStyle(
                            color: AppColors.headings,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const StatusBadge(
                        label: 'Verified',
                        tone: BadgeTone.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${venue.rating.toStringAsFixed(1)} (${venue.ratingCount})',
                        style: const TextStyle(
                          color: AppColors.headings,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${venue.sport.label} · ${venue.format}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${venue.sector.label} · ${venue.address}',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Price per hour',
                            style: TextStyle(
                              color: AppColors.onDarkContainerMint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          formatRwf(venue.pricePerHour),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Surface & amenities',
                    style: TextStyle(
                      color: AppColors.headings,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Amenity(label: venue.surface, icon: Icons.layers_outlined),
                      for (final amenity in venue.amenities)
                        _Amenity(label: amenity, icon: Icons.check_circle_outline),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Reviews',
                          style: TextStyle(
                            color: AppColors.headings,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReviewsScreen(venueId: venue.id),
                          ),
                        ),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  if (reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No reviews yet. Be the first to play and rate this pitch.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    )
                  else
                    for (final review in reviews.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReviewPreview(review: review),
                      ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DateTimeSelectionScreen(venue: venue),
                  ),
                ),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Book a slot'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    if (venue.photos.isEmpty) {
      return Container(
        height: 190,
        color: AppColors.darkContainer,
        child: Icon(
          venue.sport == Sport.basketball
              ? Icons.sports_basketball
              : Icons.sports_soccer,
          size: 76,
          color: AppColors.accent,
        ),
      );
    }
    return Image.network(
      venue.photos.first,
      height: 190,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: 190,
        color: AppColors.darkContainer,
        alignment: Alignment.center,
        child: const Icon(Icons.stadium, size: 64, color: AppColors.accent),
      ),
    );
  }
}

class _Amenity extends StatelessWidget {
  const _Amenity({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPreview extends StatelessWidget {
  const _ReviewPreview({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(
                    color: AppColors.headings,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                if (review.verified)
                  const StatusBadge(
                    label: 'Verified',
                    tone: BadgeTone.success,
                  ),
                const Spacer(),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            if (review.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                review.text,
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              formatDateShort(review.createdAt),
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
