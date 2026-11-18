import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../models/user_profile.dart';
import '../../repositories/notification_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';
import '../common/notifications_screen.dart';

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final profile = session.profile;
    final uid = session.uid;
    if (profile == null || uid == null) {
      return const Scaffold(body: LoadingView(message: 'Loading profile…'));
    }
    final notifications = context.read<NotificationRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => _edit(context, session, profile),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.darkContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        profile.name.isEmpty
                            ? '?'
                            : profile.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.darkContainer,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: AppColors.onDarkContainerWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            profile.position ?? 'No preferred position',
                            style: const TextStyle(
                              color: AppColors.onDarkContainerMint,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          StatusBadge(
                            label: profile.role.label,
                            tone: BadgeTone.success,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Reliability',
                        value:
                            '${profile.reliabilityScore.toStringAsFixed(0)}%',
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Games',
                        value: '${profile.gamesPlayed}',
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'No-shows',
                        value: '${profile.noShows}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: profile.phone,
                  ),
                  if (profile.email != null)
                    _InfoRow(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      value: profile.email!,
                    ),
                  _InfoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Account',
                    value: profile.status == UserStatus.active
                        ? 'Active'
                        : 'Suspended',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppColors.headings,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: const Text('See all'),
              ),
            ],
          ),
          AsyncStreamView<List<AppNotification>>(
            stream: notifications.watchNotifications(uid),
            loadingMessage: 'Loading notifications…',
            builder: (context, items) {
              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final item in items.take(3))
                    Card(
                      color: item.read
                          ? AppColors.surface
                          : const Color(0xFFEFF8F1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              item.read
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
                              color: item.read
                                  ? AppColors.secondaryText
                                  : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: AppColors.headings,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    item.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _signOut(context, session),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(
    BuildContext context,
    SessionController session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in with your email or phone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await session.signOut();
    }
  }

  Future<void> _edit(
    BuildContext context,
    SessionController session,
    UserProfile profile,
  ) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: profile.name);
    final position = TextEditingController(text: profile.position ?? '');
    final phone = TextEditingController(text: profile.phone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: position,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Preferred position',
                    hintText: 'e.g. Striker, Point guard',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) =>
                      RegExp(r'^\+250\d{9}$').hasMatch((value ?? '').trim())
                          ? null
                          : 'Use +250 followed by 9 digits',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await session.updateProfile(
        name: name.text.trim(),
        position: position.text.trim(),
        phone: phone.text.trim(),
      );
      if (context.mounted) showAppSuccess(context, 'Profile updated.');
    } catch (error) {
      if (context.mounted) showAppError(context, error);
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onDarkContainerMint,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.headings,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
