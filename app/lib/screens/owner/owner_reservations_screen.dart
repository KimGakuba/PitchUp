import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/user_profile.dart';
import '../../models/venue.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/venue_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';

class OwnerReservationsScreen extends StatefulWidget {
  const OwnerReservationsScreen({super.key});

  @override
  State<OwnerReservationsScreen> createState() =>
      _OwnerReservationsScreenState();
}

class _OwnerReservationsScreenState extends State<OwnerReservationsScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<SessionController>().uid;
    if (uid == null) return const Scaffold(body: LoadingView());
    final venues = context.read<VenueRepository>();
    final bookings = context.read<BookingRepository>();
    final users = context.read<UserRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reservations')),
      body: AsyncStreamView<List<Venue>>(
        stream: venues.watchOwnerVenues(uid),
        loadingMessage: 'Loading reservations…',
        builder: (context, venueList) {
          if (venueList.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No pitches yet',
              message: 'Add a pitch to start receiving reservations.',
            );
          }
          final byVenue = {for (final v in venueList) v.id: v};
          return AsyncStreamView<List<UserProfile>>(
            stream: users.watchAllUsers(),
            loadingMessage: 'Loading players…',
            builder: (context, userList) {
              final userById = {for (final u in userList) u.uid: u};
              return AsyncStreamView<List<Booking>>(
                stream: bookings.watchOwnerBookings(byVenue.keys.toList()),
                loadingMessage: 'Loading reservations…',
                builder: (context, all) {
                  final filtered = _filtered(all);
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
                                    right: i == 2 ? 0 : 8,
                                  ),
                                  child: ChoiceChip(
                                    label: SizedBox(
                                      width: double.infinity,
                                      child: Center(
                                        child: Text(
                                          '${_labels[i]} (${_bucket(all, i).length})',
                                        ),
                                      ),
                                    ),
                                    selected: _filter == i,
                                    onSelected: (_) =>
                                        setState(() => _filter = i),
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: _filter == i
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
                        child: filtered.isEmpty
                            ? const EmptyView(
                                icon: Icons.event_note_outlined,
                                title: 'Nothing here',
                                message:
                                    'Reservations appear as players book your pitches.',
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final booking = filtered[index];
                                  final player = userById[booking.userId];
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  byVenue[booking.venueId]
                                                          ?.name ??
                                                      'Venue',
                                                  style: const TextStyle(
                                                    color: AppColors.headings,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                formatRwf(booking.totalPrice),
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight:
                                                      FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${formatDateShort(booking.date)} · ${formatTime12h(booking.startTime)} · ${booking.durationMin} min',
                                            style: const TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person_outline,
                                                size: 15,
                                                color:
                                                    AppColors.secondaryText,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  player == null
                                                      ? booking.userId
                                                      : '${player.name} · ${player.phone}',
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .secondaryText,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              StatusBadge(
                                                label: booking.status.name,
                                                tone: switch (booking.status) {
                                                  BookingStatus.upcoming =>
                                                    BadgeTone.primary,
                                                  BookingStatus.completed =>
                                                    BadgeTone.neutral,
                                                  BookingStatus.cancelled =>
                                                    BadgeTone.error,
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                booking.ref,
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.secondaryText,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                              const Spacer(),
                                              StatusBadge(
                                                label:
                                                    booking.paymentStatus.name,
                                                tone: switch (
                                                    booking.paymentStatus) {
                                                  BookingPaymentStatus.success =>
                                                    BadgeTone.success,
                                                  BookingPaymentStatus.failed =>
                                                    BadgeTone.error,
                                                  BookingPaymentStatus.pending =>
                                                    BadgeTone.warning,
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
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
          );
        },
      ),
    );
  }

  List<Booking> _filtered(List<Booking> all) => _bucket(all, _filter);

  List<Booking> _bucket(List<Booking> all, int bucket) {
    final list = all.where((b) {
      return switch (bucket) {
        0 => b.status == BookingStatus.upcoming && b.endsAt.isAfter(DateTime.now()),
        1 => b.status == BookingStatus.completed || b.isPast,
        _ => b.status == BookingStatus.cancelled,
      };
    }).toList();
    switch (bucket) {
      case 0:
        list.sort((a, b) => a.kickoff.compareTo(b.kickoff));
      default:
        list.sort((a, b) => b.kickoff.compareTo(a.kickoff));
    }
    return list;
  }

  static const _labels = ['Upcoming', 'Completed', 'Cancelled'];
}
