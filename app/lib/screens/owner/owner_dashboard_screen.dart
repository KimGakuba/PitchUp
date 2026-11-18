import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/venue.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/venue_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final uid = session.uid;
    if (uid == null) return const Scaffold(body: LoadingView());
    final venues = context.read<VenueRepository>();
    final bookings = context.read<BookingRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner dashboard'),
      ),
      body: AsyncStreamView<List<Venue>>(
        stream: venues.watchOwnerVenues(uid),
        loadingMessage: 'Loading your pitches…',
        builder: (context, venueList) {
          if (venueList.isEmpty) {
            return const EmptyView(
              icon: Icons.add_business_outlined,
              title: 'Add your first pitch',
              message:
                  'Use the My Pitches tab to publish a venue, then availability and reservations unlock here.',
            );
          }
          final venueIds = venueList.map((v) => v.id).toList(growable: false);
          final byId = {for (final v in venueList) v.id: v};
          return AsyncStreamView<List<Booking>>(
            stream: bookings.watchOwnerBookings(venueIds),
            loadingMessage: 'Loading reservations…',
            builder: (context, all) {
              final now = DateTime.now();
              final thisMonth = all.where((b) {
                return b.status != BookingStatus.cancelled &&
                    b.date.year == now.year &&
                    b.date.month == now.month;
              }).toList(growable: false);
              final revenue = thisMonth.fold<int>(
                0,
                (sum, b) => sum + b.totalPrice,
              );
              final upcoming = all
                  .where(
                    (b) =>
                        b.status == BookingStatus.upcoming &&
                        b.endsAt.isAfter(now),
                  )
                  .toList()
                ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
              final byVenue = <String, int>{};
              for (final booking in thisMonth) {
                byVenue.update(
                  booking.venueId,
                  (value) => value + booking.totalPrice,
                  ifAbsent: () => booking.totalPrice,
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.darkContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THIS MONTH',
                          style: TextStyle(
                            color: AppColors.onDarkContainerMint,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatRwf(revenue),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _Metric(
                              label: 'Pitches',
                              value: '${venueList.length}',
                            ),
                            const SizedBox(width: 26),
                            _Metric(
                              label: 'Bookings',
                              value: '${thisMonth.length}',
                            ),
                            const SizedBox(width: 26),
                            _Metric(
                              label: 'Upcoming',
                              value: '${upcoming.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Revenue by pitch',
                    style: TextStyle(
                      color: AppColors.headings,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final venue in venueList)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venue.name,
                                    style: const TextStyle(
                                      color: AppColors.headings,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    venue.sector.label,
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatRwf(byVenue[venue.id] ?? 0),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Text(
                    'Next reservations',
                    style: TextStyle(
                      color: AppColors.headings,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (upcoming.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'No upcoming reservations.',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      ),
                    )
                  else
                    for (final booking in upcoming.take(4))
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${booking.date.day}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    formatDateShort(booking.date)
                                        .split(' ')
                                        .last,
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      byId[booking.venueId]?.name ?? 'Venue',
                                      style: const TextStyle(
                                        color: AppColors.headings,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${formatTime12h(booking.startTime)} · ${booking.ref}',
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: booking.paymentStatus.name,
                                tone: booking.paymentStatus ==
                                        BookingPaymentStatus.success
                                    ? BadgeTone.success
                                    : BadgeTone.warning,
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.onDarkContainerWhite,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onDarkContainerMint,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
