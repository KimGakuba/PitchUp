import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../repositories/notification_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<SessionController>().uid;
    if (uid == null) {
      return const Scaffold(body: EmptyView(title: 'Signed out', message: 'Sign in to see notifications.'));
    }
    final repository = context.read<NotificationRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: AsyncStreamView<List<AppNotification>>(
        stream: repository.watchNotifications(uid),
        loadingMessage: 'Loading notifications…',
        builder: (context, notifications) {
          if (notifications.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_none,
              title: 'All quiet',
              message: 'Booking updates, game invites and payment status will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () async {
                  if (notification.read) return;
                  try {
                    await repository.markRead(notification.id);
                  } catch (error) {
                    if (context.mounted) showAppError(context, error);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.read ? AppColors.surface : const Color(0xFFEFF8F1),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                notification.read
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: notification.read
                    ? AppColors.secondaryText
                    : AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: AppColors.headings,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDateShort(notification.createdAt),
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
