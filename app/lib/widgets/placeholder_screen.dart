import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Stand-in for a screen whose real implementation lands in a later phase.
/// Keeps the navigation shell fully wired now so every route in the spec
/// is reachable and testable before its business logic exists.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String builtInPhase;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.builtInPhase,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.headings,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Coming in $builtInPhase',
                style: const TextStyle(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
