import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BadgeTone { success, warning, error, neutral, primary }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
  });

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      BadgeTone.success => AppColors.success,
      BadgeTone.warning => AppColors.warning,
      BadgeTone.error => AppColors.error,
      BadgeTone.primary => AppColors.primary,
      BadgeTone.neutral => AppColors.secondaryText,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
