import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

void showAppError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.error,
      content: Text(
        error.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

void showAppSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.success,
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

String formatDateShort(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String formatDateLong(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

String formatTime12h(String hhmm) {
  final parts = hhmm.split(':');
  final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final minute = parts.length > 1 ? parts[1] : '00';
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:$minute $suffix';
}
