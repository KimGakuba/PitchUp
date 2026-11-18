import 'package:flutter/material.dart';

import '../models/venue.dart';
import '../theme/app_colors.dart';
import '../utils/currency.dart';

class VenueCard extends StatelessWidget {
  const VenueCard({super.key, required this.venue, this.onTap});

  final Venue venue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(venue: venue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            venue.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.headings,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          venue.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.headings,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${venue.sector.label} · ${venue.format} · ${venue.surface}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(label: venue.sport.label),
                        const SizedBox(width: 6),
                        _Chip(label: '${venue.ratingCount} reviews'),
                        const Spacer(),
                        Text(
                          '${formatRwf(venue.pricePerHour)}/hr',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    if (venue.photos.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          venue.photos.first,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.darkContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        venue.sport == Sport.basketball
            ? Icons.sports_basketball
            : Icons.sports_soccer,
        color: AppColors.accent,
        size: 32,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
