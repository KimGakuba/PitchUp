import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/match_management_screen.dart';
import '../screens/admin/match_results_screen.dart';
import '../screens/owner/owner_add_pitch_screen.dart';
import '../screens/owner/owner_availability_screen.dart';
import '../screens/owner/owner_dashboard_screen.dart';
import '../screens/owner/owner_reservations_screen.dart';
import '../screens/player/explore_pitches_screen.dart';
import '../screens/player/my_bookings_screen.dart';
import '../screens/player/open_games_screen.dart';
import '../screens/player/player_home_screen.dart';
import '../screens/player/player_profile_screen.dart';
import '../state/session_controller.dart';

class _TabConfig {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder rootBuilder;

  const _TabConfig({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.rootBuilder,
  });
}

const _playerTabs = [
  _TabConfig(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    rootBuilder: _buildPlayerHome,
  ),
  _TabConfig(
    label: 'Explore',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
    rootBuilder: _buildExplore,
  ),
  _TabConfig(
    label: 'Games',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
    rootBuilder: _buildOpenGames,
  ),
  _TabConfig(
    label: 'Bookings',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note,
    rootBuilder: _buildMyBookings,
  ),
  _TabConfig(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    rootBuilder: _buildProfile,
  ),
];

const _ownerTabs = [
  _TabConfig(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    rootBuilder: _buildOwnerDashboard,
  ),
  _TabConfig(
    label: 'My Pitches',
    icon: Icons.add_business_outlined,
    selectedIcon: Icons.add_business,
    rootBuilder: _buildOwnerAddPitch,
  ),
  _TabConfig(
    label: 'Availability',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    rootBuilder: _buildOwnerAvailability,
  ),
  _TabConfig(
    label: 'Reservations',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    rootBuilder: _buildOwnerReservations,
  ),
];

const _adminTabs = [
  _TabConfig(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    rootBuilder: _buildAdminDashboard,
  ),
  _TabConfig(
    label: 'Matches',
    icon: Icons.sports_outlined,
    selectedIcon: Icons.sports,
    rootBuilder: _buildMatchManagement,
  ),
  _TabConfig(
    label: 'Results',
    icon: Icons.scoreboard_outlined,
    selectedIcon: Icons.scoreboard,
    rootBuilder: _buildMatchResults,
  ),
  _TabConfig(
    label: 'Reports',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag,
    rootBuilder: _buildAdminReports,
  ),
];

Widget _buildPlayerHome(BuildContext _) => const PlayerHomeScreen();
Widget _buildExplore(BuildContext _) => const ExplorePitchesScreen();
Widget _buildOpenGames(BuildContext _) => const OpenGamesScreen();
Widget _buildMyBookings(BuildContext _) => const MyBookingsScreen();
Widget _buildProfile(BuildContext _) => const PlayerProfileScreen();

Widget _buildOwnerDashboard(BuildContext _) => const OwnerDashboardScreen();
Widget _buildOwnerAddPitch(BuildContext _) => const OwnerAddPitchScreen();
Widget _buildOwnerAvailability(BuildContext _) =>
    const OwnerAvailabilityScreen();
Widget _buildOwnerReservations(BuildContext _) =>
    const OwnerReservationsScreen();

Widget _buildAdminDashboard(BuildContext _) => const AdminDashboardScreen();
Widget _buildMatchManagement(BuildContext _) => const MatchManagementScreen();
Widget _buildMatchResults(BuildContext _) => const MatchResultsScreen();
Widget _buildAdminReports(BuildContext _) => const AdminReportsScreen();

List<_TabConfig> _tabsFor(Role role) => switch (role) {
  Role.player => _playerTabs,
  Role.owner => _ownerTabs,
  Role.admin => _adminTabs,
};

/// The app's single navigation shell: a role-aware bottom nav bar where
/// each tab owns its own [Navigator], so screens pushed from within a tab
/// (pitch details, booking flow, game roster, ...) stay beneath the bottom
/// nav instead of covering it.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  Role? _lastRole;
  final List<GlobalKey<NavigatorState>> _navKeys = [];

  void _ensureNavKeys(int count) {
    while (_navKeys.length < count) {
      _navKeys.add(GlobalKey<NavigatorState>());
    }
  }

  void _onRoleChanged(Role role) {
    if (_lastRole != role) {
      _lastRole = role;
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionController>().role;
    _onRoleChanged(role);
    final tabs = _tabsFor(role);
    _ensureNavKeys(tabs.length);
    if (_index >= tabs.length) _index = 0;

    return PopScope(
      canPop: !(_navKeys[_index].currentState?.canPop() ?? false),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _navKeys[_index].currentState?.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < tabs.length; i++)
              Navigator(
                key: _navKeys[i],
                onGenerateRoute: (settings) => MaterialPageRoute<void>(
                  builder: tabs[i].rootBuilder,
                  settings: settings,
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final tab in tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
