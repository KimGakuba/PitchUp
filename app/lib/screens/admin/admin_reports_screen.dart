import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../models/user_profile.dart';
import '../../repositories/admin_repository.dart';
import '../../repositories/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final Set<String> _busy = {};

  @override
  Widget build(BuildContext context) {
    final reports = context.read<AdminRepository>();
    final users = context.read<UserRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & moderation')),
      body: AsyncStreamView<List<UserProfile>>(
        stream: users.watchAllUsers(),
        loadingMessage: 'Loading users…',
        builder: (context, userList) {
          final byId = {for (final u in userList) u.uid: u};
          return AsyncStreamView<List<UserReport>>(
            stream: reports.watchReports(),
            loadingMessage: 'Loading reports…',
            builder: (context, reportList) {
              if (reportList.isEmpty) {
                return const EmptyView(
                  icon: Icons.flag_outlined,
                  title: 'No reports',
                  message: 'Player reports and moderation actions appear here.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: reportList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final report = reportList[index];
                  final target = byId[report.targetId];
                  final reporter = byId[report.reporterId];
                  return _ReportCard(
                    report: report,
                    target: target,
                    reporter: reporter,
                    busy: _busy.contains(report.id),
                    onAction: (action) =>
                        _handle(context, report, action),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    UserReport report,
    String action,
  ) async {
    final labels = {
      'resolve': 'Resolve report',
      'dismiss': 'Dismiss report',
      'suspend': 'Suspend target account',
      'activate': 'Activate target account',
    };
    final destructive = action == 'suspend';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels[action] ?? 'Update report'),
        content: Text(
          destructive
              ? 'The reported user will be signed out of protected actions and '
                  'blocked from joining games until reactivated.'
              : action == 'dismiss'
                  ? 'The report will be closed without action against the player.'
                  : 'The report will be marked resolved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(labels[action] ?? 'Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _busy.add(report.id));
    try {
      await context.read<AdminRepository>().resolveReport(
            report.id,
            action: action,
          );
      if (context.mounted) {
        showAppSuccess(context, labels[action] ?? 'Report updated.');
        setState(() => _busy.remove(report.id));
      }
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
        setState(() => _busy.remove(report.id));
      }
    }
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.target,
    required this.reporter,
    required this.busy,
    required this.onAction,
  });

  final UserReport report;
  final UserProfile? target;
  final UserProfile? reporter;
  final bool busy;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final open = report.status == 'open';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    target?.name ?? report.targetId,
                    style: const TextStyle(
                      color: AppColors.headings,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                StatusBadge(
                  label: report.status,
                  tone: open ? BadgeTone.warning : BadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Reported by ${reporter?.name ?? report.reporterId} · ${formatDateShort(report.createdAt)}',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
            if (target != null) ...[
              const SizedBox(height: 3),
              Text(
                '${target!.phone} · ${target!.status.name} · ${target!.reliabilityScore.toStringAsFixed(0)}% reliable',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                report.reason,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            if (open) ...[
              const SizedBox(height: 10),
              if (busy)
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onAction('dismiss'),
                        child: const Text('Dismiss'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onAction('resolve'),
                        child: const Text('Resolve'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: target?.status == UserStatus.suspended
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        onPressed: () => onAction(
                          target?.status == UserStatus.suspended
                              ? 'activate'
                              : 'suspend',
                        ),
                        child: Text(
                          target?.status == UserStatus.suspended
                              ? 'Activate'
                              : 'Suspend',
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
