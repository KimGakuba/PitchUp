import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game.dart';
import '../../models/result.dart';
import '../../repositories/game_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/game_card.dart';
import '../../widgets/status_badge.dart';

class MatchResultsScreen extends StatefulWidget {
  const MatchResultsScreen({super.key, this.initialGameId});

  final String? initialGameId;

  @override
  State<MatchResultsScreen> createState() => _MatchResultsScreenState();
}

class _MatchResultsScreenState extends State<MatchResultsScreen> {
  late String? _gameId = widget.initialGameId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match results'),
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
      body: _gameId == null
          ? AsyncStreamView<List<GameWithContext>>(
              stream: context.read<GameRepository>().watchAllGames(),
              loadingMessage: 'Loading matches…',
              builder: (context, games) {
                if (games.isEmpty) {
                  return const EmptyView(
                    icon: Icons.scoreboard_outlined,
                    title: 'No matches yet',
                    message: 'Results can be posted once games are created.',
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
                      onTap: () =>
                          setState(() => _gameId = item.game.id),
                    );
                  },
                );
              },
            )
          : _ResultEditor(gameId: _gameId!),
    );
  }
}

class _ResultEditor extends StatefulWidget {
  const _ResultEditor({required this.gameId});

  final String gameId;

  @override
  State<_ResultEditor> createState() => _ResultEditorState();
}

class _ResultEditorState extends State<_ResultEditor> {
  int _scoreA = 0;
  int _scoreB = 0;
  bool _dirty = false;
  bool _saving = false;
  String? _loadedKey;

  @override
  Widget build(BuildContext context) {
    return AsyncStreamView<GameWithContext?>(
      stream: context.read<GameRepository>().watchGame(widget.gameId),
      loadingMessage: 'Loading match…',
      builder: (context, data) {
        if (data == null) {
          return const EmptyView(
            title: 'Match unavailable',
            message: 'This match could not be loaded.',
          );
        }
        return AsyncStreamView<GameResult?>(
          stream: context.read<GameRepository>().watchResult(widget.gameId),
          loadingMessage: 'Loading result…',
          builder: (context, result) {
            final key = result == null
                ? 'none'
                : '${result.scoreA}:${result.scoreB}';
            if (!_dirty && _loadedKey != key) {
              _scoreA = result?.scoreA ?? 0;
              _scoreB = result?.scoreB ?? 0;
              _loadedKey = key;
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.darkContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ScoreSide(
                          label: 'TEAM A',
                          score: _scoreA,
                          color: AppColors.accent,
                          onMinus: _scoreA == 0
                              ? null
                              : () => setState(() {
                                    _scoreA--;
                                    _dirty = true;
                                  }),
                          onPlus: () => setState(() {
                            _scoreA++;
                            _dirty = true;
                          }),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '–',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 30,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ScoreSide(
                          label: 'TEAM B',
                          score: _scoreB,
                          color: AppColors.warning,
                          onMinus: _scoreB == 0
                              ? null
                              : () => setState(() {
                                    _scoreB--;
                                    _dirty = true;
                                  }),
                          onPlus: () => setState(() {
                            _scoreB++;
                            _dirty = true;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (result != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Published result',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${result.scoreA} – ${result.scoreB}',
                            style: const TextStyle(
                              color: AppColors.headings,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _post,
                    icon: const Icon(Icons.publish),
                    label: Text(
                      _saving
                          ? 'Posting…'
                          : result == null
                              ? 'Post final result'
                              : 'Update result',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Posting a result marks the game completed and notifies every confirmed player.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                if (data.game.teamA.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: StatusBadge(
                      label: 'Teams not set — roster screen can shuffle them',
                      tone: BadgeTone.warning,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _post() async {
    setState(() => _saving = true);
    try {
      await context
          .read<GameRepository>()
          .postResult(widget.gameId, _scoreA, _scoreB);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
        _loadedKey = '$_scoreA:$_scoreB';
      });
      showAppSuccess(context, 'Final result posted.');
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
        setState(() => _saving = false);
      }
    }
  }
}

class _ScoreSide extends StatelessWidget {
  const _ScoreSide({
    required this.label,
    required this.score,
    required this.color,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int score;
  final Color color;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: onMinus,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: onPlus,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
