import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../repositories/venue_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<VenueRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReviewSheet(context),
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Write a review'),
      ),
      body: AsyncStreamView<List<Review>>(
        stream: repository.watchReviews(venueId),
        loadingMessage: 'Loading reviews…',
        builder: (context, reviews) {
          if (reviews.isEmpty) {
            return const EmptyView(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              message: 'Play here, then share how the pitch felt.',
            );
          }
          final average =
              reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Text(
                      average.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < average.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reviews.length} player reviews',
                          style: const TextStyle(
                            color: AppColors.onDarkContainerMint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final review in reviews)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewCard(review: review),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showReviewSheet(BuildContext context) async {
    final session = context.read<SessionController>();
    final repository = context.read<VenueRepository>();
    final profile = session.profile;
    if (profile == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _AddReviewSheet(
        userName: profile.name,
        onSubmit: (rating, text) async {
          await repository.addReview(
            venueId: venueId,
            userId: profile.uid,
            userName: profile.name,
            rating: rating,
            text: text,
          );
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
          if (context.mounted) {
            showAppSuccess(context, 'Thanks! Your review was posted.');
          }
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    review.userName.isEmpty
                        ? '?'
                        : review.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          color: AppColors.headings,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatDateShort(review.createdAt),
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (review.verified)
                  const StatusBadge(
                    label: 'Verified player',
                    tone: BadgeTone.success,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
              ),
            ),
            if (review.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.text,
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddReviewSheet extends StatefulWidget {
  const _AddReviewSheet({required this.userName, required this.onSubmit});

  final String userName;
  final Future<void> Function(int rating, String text) onSubmit;

  @override
  State<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<_AddReviewSheet> {
  final _text = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_rating, _text.text);
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate this pitch',
            style: TextStyle(
              color: AppColors.headings,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Posting as ${widget.userName}',
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.warning,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 4,
            maxLength: 400,
            decoration: const InputDecoration(
              hintText: 'How was the surface, lighting and facilities?',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post review'),
            ),
          ),
        ],
      ),
    );
  }
}
