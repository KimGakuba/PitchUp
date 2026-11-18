import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/game.dart';
import '../../models/payment.dart';
import '../../repositories/game_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';

class CostSharingScreen extends StatefulWidget {
  const CostSharingScreen._({
    required this.title,
    required this.venueName,
    required this.totalPrice,
    required this.confirmedPlayers,
    required this.perPlayer,
    required this.organizerId,
    this.gameId,
    this.bookingId,
  });

  factory CostSharingScreen.forGame(GameWithContext data) {
    return CostSharingScreen._(
      title: data.game.title,
      venueName: data.booking.venue.name,
      totalPrice: data.booking.totalPrice,
      confirmedPlayers: data.game.confirmedPlayers,
      perPlayer: data.game.costPerPlayer,
      organizerId: data.game.organizerId,
      gameId: data.game.id,
    );
  }

  factory CostSharingScreen.forBooking({
    required Booking booking,
    String? venueName,
  }) {
    return CostSharingScreen._(
      title: 'Booking ${booking.ref}',
      venueName: venueName ?? 'Your pitch',
      totalPrice: booking.totalPrice,
      confirmedPlayers: 1,
      perPlayer: booking.totalPrice,
      organizerId: booking.userId,
      bookingId: booking.id,
    );
  }

  final String title;
  final String venueName;
  final int totalPrice;
  final int confirmedPlayers;
  final int perPlayer;
  final String organizerId;
  final String? gameId;
  final String? bookingId;

  @override
  State<CostSharingScreen> createState() => _CostSharingScreenState();
}

class _CostSharingScreenState extends State<CostSharingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  PaymentProvider _provider = PaymentProvider.mtn;
  bool _busy = false;
  String? _paymentId;

  bool get _isGame => widget.gameId != null;

  @override
  void initState() {
    super.initState();
    final phone = context.read<SessionController>().profile?.phone ?? '';
    _phone = TextEditingController(
      text: phone.startsWith('+250') ? phone : '+250',
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  int get _organizerShare =>
      widget.totalPrice - widget.perPlayer * (widget.confirmedPlayers - 1);

  int _myShare(String uid) =>
      uid == widget.organizerId ? _organizerShare : widget.perPlayer;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final uid = session.uid ?? '';
    final payments = context.read<PaymentRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Split the cost')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.onDarkContainerWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.venueName,
                  style: const TextStyle(
                    color: AppColors.onDarkContainerMint,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Figure(
                      label: 'Total',
                      value: formatRwf(widget.totalPrice),
                    ),
                    const SizedBox(width: 24),
                    _Figure(
                      label: 'Players',
                      value: '${widget.confirmedPlayers}',
                    ),
                    const Spacer(),
                    _Figure(
                      label: 'Your share',
                      value: formatRwf(_myShare(uid)),
                      highlight: true,
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
                  _BreakdownRow(
                    label: 'Pitch total',
                    value: formatRwf(widget.totalPrice),
                  ),
                  _BreakdownRow(
                    label: 'Split between',
                    value:
                        '${widget.confirmedPlayers} player${widget.confirmedPlayers == 1 ? '' : 's'}',
                  ),
                  _BreakdownRow(
                    label: 'Per player',
                    value: formatRwf(widget.perPlayer),
                  ),
                  if (_organizerShare != widget.perPlayer)
                    _BreakdownRow(
                      label: 'Organizer absorbs remainder',
                      value: formatRwf(_organizerShare - widget.perPlayer),
                      muted: true,
                    ),
                  const Divider(height: 20),
                  _BreakdownRow(
                    label: 'You pay',
                    value: formatRwf(_myShare(uid)),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isGame) _PaidPlayers(gameId: widget.gameId!, currentUid: uid),
          if (_isGame) const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment method',
                  style: TextStyle(
                    color: AppColors.headings,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final provider in PaymentProvider.values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: provider == PaymentProvider.mtn ? 8 : 0,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _provider = provider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: _provider == provider
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _provider == provider
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                provider.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _provider == provider
                                      ? Colors.white
                                      : AppColors.secondaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile money number',
                    hintText: '+250780000001',
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (!RegExp(r'^\+250\d{9}$').hasMatch(v)) {
                      return 'Use +250 followed by 9 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _pay,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(
                      _busy
                          ? 'Requesting payment…'
                          : 'Pay ${formatRwf(_myShare(uid))}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_paymentId != null) ...[
            const SizedBox(height: 16),
            StreamBuilder<Payment?>(
              stream: context.read<PaymentRepository>().watchPayment(_paymentId!),
              builder: (context, snapshot) {
                final payment = snapshot.data;
                if (payment == null) {
                  return const LoadingView(message: 'Waiting for confirmation…');
                }
                return _PaymentStatus(
                  payment: payment,
                  onSimulate: _simulate,
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          StreamBuilder<List<Payment>>(
            stream: _isGame
                ? payments.watchGamePayments(widget.gameId!, uid)
                : payments.watchBookingPayments(widget.bookingId!),
            builder: (context, snapshot) {
              final history = snapshot.data ?? const <Payment>[];
              if (history.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Payment history',
                    style: TextStyle(
                      color: AppColors.headings,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final payment in history.take(5))
                    _HistoryRow(payment: payment),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pay() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final result = await context.read<PaymentRepository>().initiate(
            purpose: _isGame ? 'game' : 'booking',
            targetId: _isGame ? widget.gameId! : widget.bookingId!,
            provider: _provider,
            phone: _phone.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _paymentId = result.paymentId;
        _busy = false;
      });
      showAppSuccess(
        context,
        result.message.isEmpty
            ? 'Payment request sent. Approve the prompt on your phone.'
            : result.message,
      );
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _simulate(bool success) async {
    final id = _paymentId;
    if (id == null) return;
    try {
      await context.read<PaymentRepository>().simulateOutcome(
            id,
            success: success,
          );
      if (mounted) {
        showAppSuccess(
          context,
          success ? 'Payment marked successful.' : 'Payment marked failed.',
        );
      }
    } catch (error) {
      if (mounted) showAppError(context, error);
    }
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.onDarkContainerMint,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.accent : AppColors.onDarkContainerWhite,
            fontSize: highlight ? 20 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.muted = false,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: muted ? AppColors.secondaryText : AppColors.secondaryText,
                fontSize: muted ? 11 : 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.headings,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              fontSize: bold ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaidPlayers extends StatelessWidget {
  const _PaidPlayers({required this.gameId, required this.currentUid});

  final String gameId;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    return AsyncStreamView<List<RosterPlayer>>(
      stream: context.read<GameRepository>().watchRoster(gameId),
      loadingMessage: 'Loading players…',
      builder: (context, roster) {
        if (roster.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Player payments',
                  style: TextStyle(
                    color: AppColors.headings,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                for (final player in roster)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.uid == currentUid
                                ? '${player.name ?? 'Player'} (you)'
                                : player.name ?? 'Player',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: player.paid ? 'Paid' : 'Pending',
                          tone: player.paid
                              ? BadgeTone.success
                              : BadgeTone.warning,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentStatus extends StatelessWidget {
  const _PaymentStatus({required this.payment, required this.onSimulate});

  final Payment payment;
  final Future<void> Function(bool success) onSimulate;

  @override
  Widget build(BuildContext context) {
    final tone = switch (payment.status) {
      PaymentState.success => BadgeTone.success,
      PaymentState.failed => BadgeTone.error,
      PaymentState.pending => BadgeTone.warning,
    };
    final message = switch (payment.status) {
      PaymentState.success => 'Payment received. You are all set.',
      PaymentState.failed => 'Payment failed. You can try again.',
      PaymentState.pending =>
        'Waiting for ${payment.provider.label} confirmation…',
    };
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
                    formatRwf(payment.amount),
                    style: const TextStyle(
                      color: AppColors.headings,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                StatusBadge(
                  label: payment.status.name,
                  tone: tone,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
            if (kDebugMode && payment.status == PaymentState.pending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onSimulate(false),
                      child: const Text('Simulate failure'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onSimulate(true),
                      child: const Text('Simulate success'),
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${payment.provider.label} · ${formatRwf(payment.amount)}',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
          StatusBadge(
            label: payment.status.name,
            tone: switch (payment.status) {
              PaymentState.success => BadgeTone.success,
              PaymentState.failed => BadgeTone.error,
              PaymentState.pending => BadgeTone.warning,
            },
          ),
        ],
      ),
    );
  }
}
