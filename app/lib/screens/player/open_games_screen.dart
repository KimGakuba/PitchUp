import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game.dart';
import '../../repositories/game_repository.dart';
import '../../state/session_controller.dart';
import '../../widgets/async_views.dart';
import '../../widgets/game_card.dart';
import 'explore_pitches_screen.dart';
import 'game_details_screen.dart';

class OpenGamesScreen extends StatelessWidget {
  const OpenGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<SessionController>().uid;
    final repository = context.read<GameRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open pickup games'),
        actions: [
          IconButton(
            tooltip: 'Find a pitch',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ExplorePitchesScreen(),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: AsyncStreamView<List<GameWithContext>>(
        stream: repository.watchOpenGames(),
        loadingMessage: 'Finding games…',
        builder: (context, games) {
          if (games.isEmpty) {
            return EmptyView(
              icon: Icons.groups_outlined,
              title: 'No open games',
              message:
                  'Book a pitch and host the first pickup game in your area.',
              action: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ExplorePitchesScreen(),
                  ),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Find a pitch'),
              ),
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
                joined: uid != null && item.game.playerIds.contains(uid),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameDetailsScreen(gameId: item.game.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
