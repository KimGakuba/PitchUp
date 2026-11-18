import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkContainer,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_soccer,
                size: 72,
                color: AppColors.accent,
              ),
              const SizedBox(height: 16),
              const Text(
                'PITCHUP',
                style: TextStyle(
                  color: AppColors.onDarkContainerWhite,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Book the pitch. Find your team. Play together.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.onDarkContainerMint,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (loading) ...[
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: AppColors.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({
    super.key,
    required this.error,
    this.onSignOut,
  });

  final Object error;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Could not start PitchUp',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headings,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Local development: start the Firebase Emulator Suite '
                      '(`npm run emulators`), then run the app again. If you '
                      'are on a physical device, pass '
                      '--dart-define=FIREBASE_EMULATOR_HOST=<your PC IP>.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => onSignOut!(),
                    child: const Text('Sign out'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.block,
                  size: 56,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account suspended',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headings,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account is on hold. Contact PitchUp support to resolve '
                  'any open reports.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: session.signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
