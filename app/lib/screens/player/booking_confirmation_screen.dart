import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/venue.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/venue_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';
import 'cost_sharing_screen.dart';
import 'game_details_screen.dart';
import 'pitch_details_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
    this.justBooked = false,
  });

  final String bookingId;
  final bool justBooked;

  @override
  Widget build(BuildContext context) {
    final bookings = context.read<BookingRepository>();
    final venues = context.read<VenueRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Booking receipt')),
      body: AsyncStreamView<Booking?>(
        stream: bookings.watchBooking(bookingId),
        loadingMessage: 'Loading booking…',
        builder: (context, booking) {
          if (booking == null) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'Booking not found',
              message: 'It may have been removed. Check My bookings.',
            );
          }
          return AsyncStreamView<Venue?>(
            stream: venues.watchVenue(booking.venueId),
            loadingMessage: 'Loading pitch…',
            builder: (context, venue) => _Receipt(
              bookingId: booking.id,
              booking: booking,
              venue: venue,
              justBooked: justBooked,
            ),
          );
        },
      ),
    );
  }
}

class _Receipt extends StatefulWidget {
  const _Receipt({
    required this.bookingId,
    required this.booking,
    required this.venue,
    required this.justBooked,
  });

  final String bookingId;
  final Booking booking;
  final Venue? venue;
  final bool justBooked;

  @override
  State<_Receipt> createState() => _ReceiptState();
}

class _ReceiptState extends State<_Receipt> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final venue = widget.venue;
    final cancelled = booking.status == BookingStatus.cancelled;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        if (widget.justBooked)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Slot locked. Your booking reference is below.',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkContainer,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'BOOKING REFERENCE',
                    style: TextStyle(
                      color: AppColors.onDarkContainerMint,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(
                    label: cancelled ? 'CANCELLED' : 'CONFIRMED',
                    tone: cancelled ? BadgeTone.error : BadgeTone.success,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SelectableText(
                booking.ref.isEmpty ? booking.id : booking.ref,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                venue?.name ?? 'Venue',
                style: const TextStyle(
                  color: AppColors.onDarkContainerWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (venue != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${venue.sector.label} · ${venue.address}',
                  style: const TextStyle(
                    color: AppColors.onDarkContainerMint,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _ReceiptRow(
                label: 'Date',
                value: formatDateLong(booking.date),
              ),
              _ReceiptRow(
                label: 'Time',
                value:
                    '${formatTime12h(booking.startTime)} · ${booking.durationMin} min',
              ),
              _ReceiptRow(
                label: 'Total',
                value: formatRwf(booking.totalPrice),
                highlight: true,
              ),
              _ReceiptRow(
                label: 'Payment',
                value: booking.paymentStatus.name.toUpperCase(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!cancelled) ...[
          FilledButton.icon(
            onPressed: _busy ? null : () => _convertToGame(context),
            icon: const Icon(Icons.groups),
            label: const Text('Host a pickup game'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CostSharingScreen.forBooking(
                          booking: booking,
                          venueName: venue?.name,
                        ),
                      ),
                    ),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Pay via MoMo / Airtel'),
          ),
          if (venue != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PitchDetailsScreen(venueId: venue.id),
                ),
              ),
              icon: const Icon(Icons.stadium_outlined),
              label: const Text('View pitch'),
            ),
          ],
        ],
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: cancelled || _busy ? null : () => _cancel(context),
          icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
          label: const Text(
            'Cancel booking',
            style: TextStyle(color: AppColors.error),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Cancellations within 2 hours of kickoff are marked late and are not refunded in the current payment setup.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text(
          'This frees the slot immediately. If kickoff is within 2 hours, the '
          'booking is treated as a late cancellation and is not refunded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<BookingRepository>().cancelBooking(widget.bookingId);
      if (context.mounted) {
        showAppSuccess(context, 'Booking cancelled.');
        setState(() => _busy = false);
      }
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _convertToGame(BuildContext context) async {
    final venue = widget.venue;
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(
      text: 'Pickup ${venue?.sport.label ?? 'game'} at ${venue?.name ?? 'PitchUp'}',
    );
    final maxPlayers = TextEditingController(text: '10');
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Host a pickup game'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Game title'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter a title'
                    : null,
              ),
              TextFormField(
                controller: maxPlayers,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max players',
                  helperText: 'Between 2 and 22',
                ),
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  if (n == null || n < 2 || n > 22) {
                    return 'Use 2–22 players';
                  }
                  return null;
                },
              ),
            ],
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
            child: const Text('Create game'),
          ),
        ],
      ),
    );
    if (result != true || !context.mounted) return;
    setState(() => _busy = true);
    try {
      final gameId = await context.read<BookingRepository>().convertToGame(
            bookingId: widget.bookingId,
            title: title.text.trim(),
            maxPlayers: int.parse(maxPlayers.text.trim()),
          );
      if (!context.mounted) return;
      setState(() => _busy = false);
      if (gameId.isEmpty) {
        showAppError(context, 'Game could not be created.');
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameDetailsScreen(gameId: gameId),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
        setState(() => _busy = false);
      }
    }
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.onDarkContainerMint,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlight
                    ? AppColors.accent
                    : AppColors.onDarkContainerWhite,
                fontWeight: FontWeight.w700,
                fontSize: highlight ? 17 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
