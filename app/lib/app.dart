import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation/root_shell.dart';
import 'repositories/admin_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/game_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/venue_repository.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/common/startup_screens.dart';
import 'services/functions_api.dart';
import 'state/connectivity_controller.dart';
import 'state/session_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/offline_banner.dart';

class PitchUpApp extends StatelessWidget {
  const PitchUpApp({super.key, this.initError});

  final Object? initError;

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        title: 'PITCHUP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: StartupErrorScreen(error: initError!),
      );
    }

    final functions = FunctionsApi();
    final users = UserRepository();
    final notifications = NotificationRepository(functions: functions);

    return MultiProvider(
      providers: [
        Provider.value(value: functions),
        Provider.value(value: users),
        Provider.value(value: notifications),
        Provider(create: (_) => VenueRepository()),
        Provider(create: (_) => BookingRepository(functions: functions)),
        Provider(
          create: (_) =>
              GameRepository(functions: functions, users: users),
        ),
        Provider(create: (_) => PaymentRepository(functions: functions)),
        Provider(create: (_) => AdminRepository(functions: functions)),
        ChangeNotifierProvider(
          create: (_) => SessionController(
            users: users,
            notifications: notifications,
          )..start(),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectivityController()..start(),
        ),
      ],
      child: MaterialApp(
        title: 'PITCHUP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) {
          return Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          );
        },
        home: const AppGate(),
      ),
    );
  }
}

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return switch (session.status) {
      SessionStatus.starting => const SplashScreen(),
      SessionStatus.loading => const SplashScreen(loading: true),
      SessionStatus.signedOut => const SignInScreen(),
      SessionStatus.needsProfile => const ProfileSetupScreen(),
      SessionStatus.error => StartupErrorScreen(
        error: session.error ?? 'Something went wrong.',
        onSignOut: session.signOut,
      ),
      SessionStatus.ready =>
        session.suspended ? const SuspendedScreen() : const RootShell(),
    };
  }
}
