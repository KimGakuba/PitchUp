import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/game.dart';
import '../../models/user_profile.dart';
import '../../models/venue.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/game_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/venue_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/game_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../common/notifications_screen.dart';
import 'booking_confirmation_screen.dart';
import 'explore_pitches_screen.dart';
import 'game_details_screen.dart';
import 'open_games_screen.dart';

class PlayerHomeScreen extends StatelessWidget {
  const PlayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final uid = session.uid;
    final profile = session.profile;
    if (uid == null || profile == null) {
      return const LoadingView(message: 'Loading your profile…');
    }

    final venues = context.read<VenueRepository>().watchVenues();
    final bookings = context.read<BookingRepository>().watchMyBookings(uid);
    final games = context.read<GameRepository>().watchOpenGames();

    return Scaffold(
      appBar: AppBar(
        title: const _HomeTitle(),
        actions: [
          _NotificationBell(uid: uid),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncStreamView<List<Venue>>(
        stream: venues,
        loadingMessage: 'Loading pitches…',
        builder: (context, venueList) {
          final byId = {for (final v in venueList) v.id: v};
          return AsyncStreamView<List<Booking>>(
            stream: bookings,
            loadingMessage: 'Loading your bookings…',
            builder: (context, bookingList) {
              final upcoming = bookingList
                  .where(
                    (b) =>
                        b.status == BookingStatus.upcoming &&
                        b.endsAt.isAfter(DateTime.now()),
                  )
                  .toList()
                ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
              final next = upcoming.isEmpty ? null : upcoming.first;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _HeroCard(profile: profile, next: next, venue: next == null ? null : byId[next.venueId]),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.search,
                          label: 'Find a pitch',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ExplorePitchesScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.groups,
                          label: 'Open games',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const OpenGamesScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Your next booking'),
                  if (next != null)
                    _NextBookingCard(
                      booking: next,
                      venue: byId[next.venueId],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BookingConfirmationScreen(
                            bookingId: next.id,
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ExplorePitchesScreen(),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.event_available, color: AppColors.primary),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No upcoming bookings. Find a pitch and lock in your slot.',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Pickup games near you',
                    actionLabel: 'See all',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OpenGamesScreen(),
                      ),
                    ),
                  ),
                  AsyncStreamView<List<GameWithContext>>(
                    stream: games,
                    loadingMessage: 'Loading pickup games…',
                    builder: (context, gameList) {
                      if (gameList.isEmpty) {
                        return const EmptyView(
                          icon: Icons.groups_outlined,
                          title: 'No open games yet',
                          message: 'Convert one of your bookings into a game and invite players.',
                        );
                      }
                      return Column(
                        children: [
                          for (final game in gameList.take(3))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GameCard(
                                contextData: game,
                                joined: game.game.playerIds.contains(uid),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => GameDetailsScreen(
                                      gameId: game.game.id,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final first =
        (session.profile?.name ?? 'Player').trim().split(RegExp(r'\s+')).first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PITCHUP',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
        Text(
          'Muraho, $first',
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final notifications = context.read<NotificationRepository>();
    return StreamBuilder(
      stream: notifications.watchNotifications(uid),
      builder: (context, snapshot) {
        final unread = snapshot.data
                ?.where((n) => !n.read)
                .length ??
            0;
        return Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          child: IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.next,
    required this.venue,
  });

  final UserProfile profile;
  final Booking? next;
  final Venue? venue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR RELIABILITY',
                  style: TextStyle(
                    color: AppColors.onDarkContainerMint,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '${profile.reliabilityScore.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (profile.reliabilityScore / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 16),
          if (next != null) ...[
            Text(
              venue?.name ?? 'Your next pitch',
              style: const TextStyle(
                color: AppColors.onDarkContainerWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatDateLong(next!.date)} · ${formatTime12h(next!.startTime)} · ${next!.durationMin} min',
              style: const TextStyle(
                color: AppColors.onDarkContainerMint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            const Text(
              'Ready for your next game?',
              style: TextStyle(
                color: AppColors.onDarkContainerWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                label: 'Games',
                value: '${profile.gamesPlayed}',
              ),
              const SizedBox(width: 20),
              _Stat(label: 'No-shows', value: '${profile.noShows}'),
              const Spacer(),
              const StatusBadge(label: 'Active player', tone: BadgeTone.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.onDarkContainerMint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.headings,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextBookingCard extends StatelessWidget {
  const _NextBookingCard({
    required this.booking,
    required this.venue,
    required this.onTap,
  });

  final Booking booking;
  final Venue? venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  const StatusBadge(
                    label: 'Upcoming',
                    tone: BadgeTone.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: AppColors.secondaryText),
                  const SizedBox(width: 6),
                  Text(
                    '${formatDateShort(booking.date)} · ${formatTime12h(booking.startTime)}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatRwf(booking.totalPrice),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
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
