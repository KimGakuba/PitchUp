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
import 'booking_confirmation_screen.dart';
import 'explore_pitches_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<SessionController>().uid;
    if (uid == null) {
      return const Scaffold(body: LoadingView());
    }
    final bookings = context.read<BookingRepository>();
    final venues = context.read<VenueRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My bookings'),
        actions: [
          IconButton(
            tooltip: 'Find a pitch',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ExplorePitchesScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AsyncStreamView<List<Venue>>(
        stream: venues.watchVenues(),
        loadingMessage: 'Loading bookings…',
        builder: (context, venueList) {
          final byId = {for (final v in venueList) v.id: v};
          return AsyncStreamView<List<Booking>>(
            stream: bookings.watchMyBookings(uid),
            loadingMessage: 'Loading your bookings…',
            builder: (context, all) {
              final groups = _group(all);
              final shown = groups[_selected];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        for (var i = 0; i < _labels.length; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: i == _labels.length - 1 ? 0 : 8,
                              ),
                              child: ChoiceChip(
                                label: SizedBox(
                                  width: double.infinity,
                                  child: Center(
                                    child: Text(
                                      '${_labels[i]} (${groups[i].length})',
                                    ),
                                  ),
                                ),
                                selected: _selected == i,
                                onSelected: (_) =>
                                    setState(() => _selected = i),
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _selected == i
                                      ? Colors.white
                                      : AppColors.secondaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: shown.isEmpty
                        ? EmptyView(
                            icon: Icons.event_busy_outlined,
                            title: 'No ${_labels[_selected].toLowerCase()} bookings',
                            message: _selected == 0
                                ? 'Find a pitch and lock in your next game.'
                                : 'Bookings will appear here once they change status.',
                            action: _selected == 0
                                ? FilledButton.icon(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ExplorePitchesScreen(),
                                      ),
                                    ),
                                    icon: const Icon(Icons.search),
                                    label: const Text('Explore pitches'),
                                  )
                                : null,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: shown.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final booking = shown[index];
                              return _BookingCard(
                                booking: booking,
                                venue: byId[booking.venueId],
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => BookingConfirmationScreen(
                                      bookingId: booking.id,
                                    ),
                                  ),
                                ),
                              );
                            },
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

  List<List<Booking>> _group(List<Booking> all) {
    final upcoming = <Booking>[];
    final completed = <Booking>[];
    final cancelled = <Booking>[];
    for (final booking in all) {
      if (booking.status == BookingStatus.cancelled) {
        cancelled.add(booking);
      } else if (booking.status == BookingStatus.completed || booking.isPast) {
        completed.add(booking);
      } else {
        upcoming.add(booking);
      }
    }
    upcoming.sort((a, b) => a.kickoff.compareTo(b.kickoff));
    completed.sort((a, b) => b.kickoff.compareTo(a.kickoff));
    cancelled.sort((a, b) => b.kickoff.compareTo(a.kickoff));
    return [upcoming, completed, cancelled];
  }

  static const _labels = ['Upcoming', 'Completed', 'Cancelled'];
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.venue,
    required this.onTap,
  });

  final Booking booking;
  final Venue? venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = switch (booking.status) {
      BookingStatus.upcoming => BadgeTone.primary,
      BookingStatus.completed => BadgeTone.neutral,
      BookingStatus.cancelled => BadgeTone.error,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      venue?.name ?? 'Venue',
                      style: const TextStyle(
                        color: AppColors.headings,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusBadge(
                    label: booking.status.name,
                    tone: status,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.event,
                    size: 15,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${formatDateShort(booking.date)} · ${formatTime12h(booking.startTime)} · ${booking.durationMin} min',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    booking.ref,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(
                    label: booking.paymentStatus.name,
                    tone: switch (booking.paymentStatus) {
                      BookingPaymentStatus.success => BadgeTone.success,
                      BookingPaymentStatus.failed => BadgeTone.error,
                      BookingPaymentStatus.pending => BadgeTone.warning,
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatRwf(booking.totalPrice),
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
      ),
    );
  }
}
