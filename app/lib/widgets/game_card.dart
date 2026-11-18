import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/venue.dart';
import '../theme/app_colors.dart';
import '../utils/currency.dart';
import '../utils/ui.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.contextData,
    this.onTap,
    this.joined = false,
  });

  final GameWithContext contextData;
  final VoidCallback? onTap;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    final game = contextData.game;
    final booking = contextData.booking;
    final fill = game.maxPlayers == 0
        ? 0.0
        : (game.confirmedPlayers / game.maxPlayers).clamp(0.0, 1.0);
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      game.sport == Sport.basketball ? 'BASKETBALL' : 'FOOTBALL',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (joined)
                    const _Tag(label: 'JOINED', color: AppColors.success)
                  else
                    _Tag(
                      label: game.status == GameStatus.full ? 'FULL' : 'OPEN',
                      color: game.status == GameStatus.full
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                game.title,
                style: const TextStyle(
                  color: AppColors.headings,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.venue.name,
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
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatDateShort(game.kickoff),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatTime12h(booking.startTime),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${formatRwf(game.costPerPlayer)}/player',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: fill,
                        minHeight: 7,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${game.confirmedPlayers}/${game.maxPlayers}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.headings,
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
