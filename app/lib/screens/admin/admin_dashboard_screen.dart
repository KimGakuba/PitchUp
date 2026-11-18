import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/game.dart';
import '../../models/report.dart';
import '../../models/role.dart';
import '../../models/user_profile.dart';
import '../../models/venue.dart';
import '../../repositories/admin_repository.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/game_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/venue_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = context.read<UserRepository>();
    final venues = context.read<VenueRepository>();
    final games = context.read<GameRepository>();
    final reports = context.read<AdminRepository>();
    final bookings = context.read<BookingRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      body: AsyncStreamView<List<UserProfile>>(
        stream: users.watchAllUsers(),
        loadingMessage: 'Loading platform health…',
        builder: (context, userList) => AsyncStreamView<List<Venue>>(
          stream: venues.watchVenues(),
          loadingMessage: 'Loading venues…',
          builder: (context, venueList) => AsyncStreamView<
              List<GameWithContext>>(
            stream: games.watchAllGames(),
            loadingMessage: 'Loading games…',
            builder: (context, gameList) => AsyncStreamView<List<UserReport>>(
              stream: reports.watchReports(),
              loadingMessage: 'Loading reports…',
              builder: (context, reportList) =>
                  AsyncStreamView<List<Booking>>(
                stream: bookings.watchAllBookings(),
                loadingMessage: 'Loading bookings…',
                builder: (context, bookingList) {
                  final openReports = reportList
                      .where((r) => r.status == 'open')
                      .toList(growable: false);
                  final paid = bookingList.where(
                    (b) => b.paymentStatus == BookingPaymentStatus.success,
                  );
                  final revenue = paid.fold<int>(
                    0,
                    (sum, b) => sum + b.totalPrice,
                  );
                  final owners = userList
                      .where((u) => u.role == Role.owner)
                      .length;
                  final suspended = userList
                      .where((u) => u.status == UserStatus.suspended)
                      .length;
                  final openGames = gameList
                      .where((g) =>
                          g.game.status == GameStatus.open ||
                          g.game.status == GameStatus.full)
                      .length;
                  final userById = {for (final u in userList) u.uid: u};
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
                              'PLATFORM GMV (PAID BOOKINGS)',
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
                            Wrap(
                              spacing: 22,
                              runSpacing: 10,
                              children: [
                                _Metric(
                                  label: 'Users',
                                  value: '${userList.length}',
                                ),
                                _Metric(
                                  label: 'Owners',
                                  value: '$owners',
                                ),
                                _Metric(
                                  label: 'Venues',
                                  value: '${venueList.length}',
                                ),
                                _Metric(
                                  label: 'Open games',
                                  value: '$openGames',
                                ),
                                _Metric(
                                  label: 'Bookings',
                                  value: '${bookingList.length}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _AlertCard(
                              icon: Icons.flag_outlined,
                              label: 'Open reports',
                              value: '${openReports.length}',
                              tone: openReports.isEmpty
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AlertCard(
                              icon: Icons.block_outlined,
                              label: 'Suspended',
                              value: '$suspended',
                              tone: suspended == 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Reports needing attention',
                              style: TextStyle(
                                color: AppColors.headings,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (openReports.isNotEmpty)
                            const StatusBadge(
                              label: 'Action needed',
                              tone: BadgeTone.warning,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (openReports.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No open reports. The community is behaving.',
                                    style: TextStyle(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        for (final report in openReports.take(4))
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(13),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userById[report.targetId]?.name ??
                                              report.targetId,
                                          style: const TextStyle(
                                            color: AppColors.headings,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        formatDateShort(report.createdAt),
                                        style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    report.reason,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
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
            fontSize: 17,
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

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: tone),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.headings,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
