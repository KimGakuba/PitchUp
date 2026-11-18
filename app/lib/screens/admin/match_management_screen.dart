import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game.dart';
import '../../repositories/game_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/game_card.dart';
import '../../widgets/status_badge.dart';

class MatchManagementScreen extends StatefulWidget {
  const MatchManagementScreen({super.key, this.initialGameId});

  final String? initialGameId;

  @override
  State<MatchManagementScreen> createState() => _MatchManagementScreenState();
}

class _MatchManagementScreenState extends State<MatchManagementScreen> {
  late String? _gameId = widget.initialGameId;
  final Set<String> _busyUids = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match management'),
        leading: _gameId == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (widget.initialGameId != null) {
                    Navigator.of(context).maybePop();
                  } else {
                    setState(() => _gameId = null);
                  }
                },
              ),
      ),
      body: _gameId == null ? _buildList(context) : _buildManager(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return AsyncStreamView<List<GameWithContext>>(
      stream: context.read<GameRepository>().watchAllGames(),
      loadingMessage: 'Loading matches…',
      builder: (context, games) {
        if (games.isEmpty) {
          return const EmptyView(
            icon: Icons.sports_outlined,
            title: 'No matches yet',
            message: 'Games appear here once players convert bookings.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: games.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = games[index];
            return GameCard(
              contextData: item,
              onTap: () => setState(() => _gameId = item.game.id),
            );
          },
        );
      },
    );
  }

  Widget _buildManager(BuildContext context) {
    final gameId = _gameId!;
    return AsyncStreamView<GameWithContext?>(
      stream: context.read<GameRepository>().watchGame(gameId),
      loadingMessage: 'Loading match…',
      builder: (context, data) {
        if (data == null) {
          return const EmptyView(
            title: 'Match unavailable',
            message: 'This match could not be loaded.',
          );
        }
        return AsyncStreamView<List<RosterPlayer>>(
          stream: context.read<GameRepository>().watchRoster(gameId),
          loadingMessage: 'Loading players…',
          builder: (context, roster) {
            final present = roster
                .where((p) => p.attendance == Attendance.present)
                .length;
            final excused = roster
                .where((p) => p.attendance == Attendance.excused)
                .length;
            final noShow = roster
                .where((p) => p.attendance == Attendance.noShow)
                .length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  data.game.title,
                  style: const TextStyle(
                    color: AppColors.headings,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${data.booking.venue.name} · ${formatDateShort(data.game.kickoff)} · ${formatTime12h(data.booking.startTime)}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppColors.darkContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _Count(label: 'Present', value: present, color: AppColors.success),
                        _Count(
                          label: 'Excused',
                          value: excused,
                          color: AppColors.warning,
                        ),
                        _Count(
                          label: 'No-show',
                          value: noShow,
                          color: AppColors.error,
                        ),
                        const Spacer(),
                        Text(
                          '${roster.length} players',
                          style: const TextStyle(
                            color: AppColors.onDarkContainerMint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (roster.isEmpty)
                  const EmptyView(
                    icon: Icons.groups_outlined,
                    title: 'No players',
                    message: 'Nobody has joined this game yet.',
                  )
                else
                  for (final player in roster)
                    _AttendanceTile(
                      player: player,
                      busy: _busyUids.contains(player.uid),
                      onChanged: (status) => _mark(
                        context,
                        gameId,
                        player.uid,
                        status,
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mark(
    BuildContext context,
    String gameId,
    String uid,
    Attendance status,
  ) async {
    final wire = status.wireName;
    if (wire == null) return;
    setState(() => _busyUids.add(uid));
    try {
      await context
          .read<GameRepository>()
          .markAttendance(gameId, {uid: wire});
      if (context.mounted) {
        showAppSuccess(context, 'Attendance saved.');
      }
    } catch (error) {
      if (context.mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => _busyUids.remove(uid));
    }
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onDarkContainerMint,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.player,
    required this.busy,
    required this.onChanged,
  });

  final RosterPlayer player;
  final bool busy;
  final ValueChanged<Attendance> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    (player.name ?? '?').isEmpty
                        ? '?'
                        : (player.name ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name ?? 'Player',
                        style: const TextStyle(
                          color: AppColors.headings,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${player.reliabilityScore.toStringAsFixed(0)}% reliable · ${player.gamesPlayed} games',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  StatusBadge(
                    label: player.paid ? 'Paid' : 'Pending',
                    tone:
                        player.paid ? BadgeTone.success : BadgeTone.warning,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in [
                  Attendance.present,
                  Attendance.excused,
                  Attendance.noShow,
                ])
                  ChoiceChip(
                    label: Text(option.label),
                    selected: player.attendance == option,
                    onSelected: busy ? null : (_) => onChanged(option),
                    selectedColor: switch (option) {
                      Attendance.present => AppColors.success,
                      Attendance.excused => AppColors.warning,
                      Attendance.noShow => AppColors.error,
                      Attendance.none => AppColors.secondaryText,
                    },
                    labelStyle: TextStyle(
                      color: player.attendance == option
                          ? Colors.white
                          : AppColors.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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
