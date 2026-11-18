import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.headings,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.secondaryText),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.headings,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Standard loading/error/empty wrapper around a Firestore stream.
class AsyncStreamView<T> extends StatelessWidget {
  const AsyncStreamView({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingMessage = 'Loading…',
    this.empty,
    this.onRetry,
  });

  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final String loadingMessage;
  final bool Function(T data)? empty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(
            message: snapshot.error.toString(),
            onRetry: onRetry,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingView(message: loadingMessage);
        }
        final data = snapshot.data;
        if (data == null) {
          return const LoadingView();
        }
        if (empty?.call(data) ?? false) {
          return const EmptyView(
            title: 'Nothing here yet',
            message: 'Check back soon.',
          );
        }
        return builder(context, data);
      },
    );
  }
}
