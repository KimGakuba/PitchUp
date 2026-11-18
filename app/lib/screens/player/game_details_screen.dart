import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game.dart';
import '../../models/result.dart';
import '../../models/role.dart';
import '../../models/venue.dart';
import '../../repositories/game_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';
import '../admin/match_management_screen.dart';
import '../admin/match_results_screen.dart';
import 'cost_sharing_screen.dart';
import 'game_roster_screen.dart';

class GameDetailsScreen extends StatefulWidget {
  const GameDetailsScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final uid = session.uid ?? '';
    final repository = context.read<GameRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Game details')),
      body: AsyncStreamView<GameWithContext?>(
        stream: repository.watchGame(widget.gameId),
        loadingMessage: 'Loading game…',
        builder: (context, data) {
          if (data == null) {
            return const EmptyView(
              icon: Icons.sports_outlined,
              title: 'Game unavailable',
              message: 'This game may have been cancelled or removed.',
            );
          }
          final game = data.game;
          final isJoined = game.playerIds.contains(uid);
          final isOrganizer = game.organizerId == uid;
          final canManage = isOrganizer || session.role == Role.admin;
          final finished = game.status == GameStatus.completed ||
              game.status == GameStatus.cancelled;
          return AsyncStreamView<List<RosterPlayer>>(
            stream: repository.watchRoster(game.id),
            loadingMessage: 'Loading roster…',
            builder: (context, roster) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _GameHero(data: data, isJoined: isJoined),
                  const SizedBox(height: 16),
                  _CostCard(data: data),
                  const SizedBox(height: 12),
                  AsyncStreamView<GameResult?>(
                    stream: repository.watchResult(game.id),
                    loadingMessage: 'Loading result…',
                    builder: (context, result) {
                      if (result == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ResultCard(result: result),
                      );
                    },
                  ),
                  _RosterCard(
                    game: game,
                    roster: roster,
                    organizerId: game.organizerId,
                    canManage: canManage,
                    onViewAll: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GameRosterScreen(gameId: game.id),
                      ),
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Organizer tools',
                      style: TextStyle(
                        color: AppColors.headings,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MatchManagementScreen(
                                  initialGameId: game.id,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text('Attendance'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MatchResultsScreen(
                                  initialGameId: game.id,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.scoreboard_outlined),
                            label: const Text('Result'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _shuffle(context, game),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Shuffle Team A / Team B'),
                    ),
                  ],
                  if (isOrganizer) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'As organizer, cancel the linked booking to cancel this game. '
                      'You cannot leave the roster.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (!finished)
                    if (!isJoined)
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: game.status == GameStatus.full || _busy
                              ? null
                              : () => _join(context),
                          icon: const Icon(Icons.group_add),
                          label: Text(
                            game.status == GameStatus.full
                                ? 'Game is full'
                                : 'Join game · ${formatRwf(game.costPerPlayer)}',
                          ),
                        ),
                      )
                    else if (!isOrganizer)
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _leave(context),
                          icon: const Icon(Icons.logout, color: AppColors.error),
                          label: const Text(
                            'Leave game',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                  if (isJoined && !finished) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CostSharingScreen.forGame(data),
                        ),
                      ),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Share the cost'),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _join(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join this game?'),
        content: const Text(
          'You commit to paying your share and showing up on time. '
          'No-shows lower your reliability score, which organizers can see.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Join game'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _busy = true);
    try {
      final result = await context.read<GameRepository>().joinGame(widget.gameId);
      if (!context.mounted) return;
      setState(() => _busy = false);
      showAppSuccess(
        context,
        result.alreadyJoined
            ? 'You are already in this game.'
            : 'You joined. New split: ${formatRwf(result.costPerPlayer)} each.',
      );
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _leave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this game?'),
        content: const Text(
          'Your spot opens up and the cost is recalculated for the remaining '
          'players. Payments you already made are not automatically refunded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<GameRepository>().leaveGame(widget.gameId);
      if (context.mounted) {
        showAppSuccess(context, 'You left the game.');
        setState(() => _busy = false);
      }
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _shuffle(BuildContext context, Game game) async {
    final players = [...game.playerIds]..shuffle(Random());
    final half = (players.length / 2).ceil();
    final teamA = players.take(half).toList(growable: false);
    final teamB = players.skip(half).toList(growable: false);
    try {
      await context.read<GameRepository>().setTeams(
            game.id,
            teamA,
            teamB,
          );
      if (context.mounted) {
        showAppSuccess(context, 'Teams updated.');
      }
    } catch (error) {
      if (context.mounted) showAppError(context, error);
    }
  }
}

class _GameHero extends StatelessWidget {
  const _GameHero({required this.data, required this.isJoined});

  final GameWithContext data;
  final bool isJoined;

  @override
  Widget build(BuildContext context) {
    final game = data.game;
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
              StatusBadge(
                label: game.status.name,
                tone: game.status == GameStatus.open
                    ? BadgeTone.success
                    : game.status == GameStatus.full
                        ? BadgeTone.warning
                        : BadgeTone.neutral,
              ),
              const Spacer(),
              if (isJoined)
                const StatusBadge(
                  label: 'You are in',
                  tone: BadgeTone.success,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            game.title,
            style: const TextStyle(
              color: AppColors.onDarkContainerWhite,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data.booking.venue.name} · ${data.booking.venue.sector.label}',
            style: const TextStyle(
              color: AppColors.onDarkContainerMint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 15,
                color: AppColors.accent,
              ),
              const SizedBox(width: 5),
              Text(
                formatDateLong(game.kickoff),
                style: const TextStyle(
                  color: AppColors.onDarkContainerWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.schedule, size: 15, color: AppColors.accent),
              const SizedBox(width: 5),
              Text(
                '${formatTime12h(data.booking.startTime)} · ${data.booking.durationMin} min',
                style: const TextStyle(
                  color: AppColors.onDarkContainerWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: game.maxPlayers == 0
                        ? 0
                        : (game.confirmedPlayers / game.maxPlayers).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${game.confirmedPlayers}/${game.maxPlayers} players',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  const _CostCard({required this.data});

  final GameWithContext data;

  @override
  Widget build(BuildContext context) {
    final game = data.game;
    final total = data.booking.totalPrice;
    final organizerShare =
        total - game.costPerPlayer * (game.confirmedPlayers - 1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _CostRow(label: 'Pitch total', value: formatRwf(total)),
            _CostRow(
              label: 'Per player',
              value: formatRwf(game.costPerPlayer),
            ),
            if (organizerShare != game.costPerPlayer)
              _CostRow(
                label: 'Organizer share',
                value: formatRwf(organizerShare),
              ),
            _CostRow(
              label: 'Confirmed players',
              value: '${game.confirmedPlayers}',
            ),
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.headings,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkContainer, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'FINAL RESULT',
              style: TextStyle(
                color: AppColors.onDarkContainerMint,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            'Team A  ${result.scoreA} – ${result.scoreB}  Team B',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterCard extends StatelessWidget {
  const _RosterCard({
    required this.game,
    required this.roster,
    required this.organizerId,
    required this.canManage,
    required this.onViewAll,
  });

  final Game game;
  final List<RosterPlayer> roster;
  final String organizerId;
  final bool canManage;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Roster',
                    style: TextStyle(
                      color: AppColors.headings,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(canManage ? 'Manage roster' : 'View all'),
                ),
              ],
            ),
            if (roster.isEmpty)
              const Text(
                'No players have joined yet.',
                style: TextStyle(color: AppColors.secondaryText),
              )
            else
              for (final player in roster.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          player.name == null || player.name!.isEmpty
                              ? '?'
                              : player.name![0].toUpperCase(),
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
                              player.uid == organizerId
                                  ? '${player.name ?? 'Player'} · organizer'
                                  : player.name ?? 'Player',
                              style: const TextStyle(
                                color: AppColors.headings,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${player.reliabilityScore.toStringAsFixed(0)}% reliable',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: player.paid ? 'Paid' : 'Pending',
                        tone:
                            player.paid ? BadgeTone.success : BadgeTone.warning,
                      ),
                    ],
                  ),
                ),
            if (roster.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${roster.length - 4} more players',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
