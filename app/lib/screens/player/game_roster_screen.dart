import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game.dart';
import '../../models/role.dart';
import '../../repositories/game_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';

class GameRosterScreen extends StatefulWidget {
  const GameRosterScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<GameRosterScreen> createState() => _GameRosterScreenState();
}

class _GameRosterScreenState extends State<GameRosterScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final repository = context.read<GameRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Game roster')),
      body: AsyncStreamView<GameWithContext?>(
        stream: repository.watchGame(widget.gameId),
        loadingMessage: 'Loading roster…',
        builder: (context, data) {
          if (data == null) {
            return const EmptyView(
              title: 'Roster unavailable',
              message: 'This game could not be loaded.',
            );
          }
          final game = data.game;
          final canManage = game.organizerId == session.uid ||
              session.role == Role.admin;
          return AsyncStreamView<List<RosterPlayer>>(
            stream: repository.watchRoster(game.id),
            loadingMessage: 'Loading players…',
            builder: (context, roster) {
              final byId = {for (final player in roster) player.uid: player};
              final hasTeams = game.teamA.isNotEmpty || game.teamB.isNotEmpty;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      color: AppColors.headings,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${data.booking.venue.name} · ${formatDateShort(game.kickoff)} · ${formatTime12h(data.booking.startTime)}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!hasTeams)
                    _PlayerList(
                      title: 'Confirmed players',
                      players: roster,
                      organizerId: game.organizerId,
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TeamColumn(
                            title: 'Team A',
                            color: AppColors.primary,
                            players: [
                              for (final id in game.teamA)
                                if (byId[id] != null) byId[id]!,
                            ],
                            organizerId: game.organizerId,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TeamColumn(
                            title: 'Team B',
                            color: AppColors.warning,
                            players: [
                              for (final id in game.teamB)
                                if (byId[id] != null) byId[id]!,
                            ],
                            organizerId: game.organizerId,
                          ),
                        ),
                      ],
                    ),
                  if (canManage) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy || roster.isEmpty
                            ? null
                            : () => _shuffle(game, roster),
                        icon: const Icon(Icons.shuffle),
                        label: Text(
                          hasTeams ? 'Re-shuffle teams' : 'Create teams',
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Teams are split evenly at random. Every confirmed player '
                        'is assigned to exactly one team.',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
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

  Future<void> _shuffle(Game game, List<RosterPlayer> roster) async {
    setState(() => _busy = true);
    final ids = roster.map((p) => p.uid).toList()..shuffle(Random());
    final half = (ids.length / 2).ceil();
    try {
      await context.read<GameRepository>().setTeams(
            game.id,
            ids.take(half).toList(growable: false),
            ids.skip(half).toList(growable: false),
          );
      if (mounted) {
        showAppSuccess(context, 'Teams updated.');
        setState(() => _busy = false);
      }
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
        setState(() => _busy = false);
      }
    }
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.title,
    required this.color,
    required this.players,
    required this.organizerId,
  });

  final String title;
  final Color color;
  final List<RosterPlayer> players;
  final String organizerId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$title (${players.length})',
                style: const TextStyle(
                  color: AppColors.headings,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (players.isEmpty)
            const Text(
              'No players',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
            )
          else
            for (final player in players)
              _PlayerTile(player: player, organizerId: organizerId),
        ],
      ),
    );
  }
}

class _PlayerList extends StatelessWidget {
  const _PlayerList({
    required this.title,
    required this.players,
    required this.organizerId,
  });

  final String title;
  final List<RosterPlayer> players;
  final String organizerId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${players.length})',
              style: const TextStyle(
                color: AppColors.headings,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            if (players.isEmpty)
              const Text(
                'No players yet.',
                style: TextStyle(color: AppColors.secondaryText),
              )
            else
              for (final player in players)
                _PlayerTile(player: player, organizerId: organizerId),
          ],
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.organizerId});

  final RosterPlayer player;
  final String organizerId;

  @override
  Widget build(BuildContext context) {
    final name = player.name ?? 'Player';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.uid == organizerId ? '$name (org)' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.headings,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${player.reliabilityScore.toStringAsFixed(0)}% · ${player.gamesPlayed} games',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                StatusBadge(
                  label: player.paid ? 'Paid' : 'Pending',
                  tone: player.paid ? BadgeTone.success : BadgeTone.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
