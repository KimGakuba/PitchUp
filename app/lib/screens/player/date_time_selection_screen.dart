import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/slot.dart';
import '../../models/venue.dart';
import '../../repositories/booking_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import 'booking_confirmation_screen.dart';

class DateTimeSelectionScreen extends StatefulWidget {
  const DateTimeSelectionScreen({super.key, required this.venue});

  final Venue venue;

  @override
  State<DateTimeSelectionScreen> createState() =>
      _DateTimeSelectionScreenState();
}

class _DateTimeSelectionScreenState extends State<DateTimeSelectionScreen> {
  static const _durations = [60, 90, 120];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
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

  late final DateTime _today;
  late DateTime _selectedDate;
  int _durationMin = 60;
  String? _selectedStart;
  bool _submitting = false;

  DateTime get _nowKigali =>
      DateTime.now().toUtc().add(const Duration(hours: 2));

  @override
  void initState() {
    super.initState();
    final now = _nowKigali;
    _today = DateTime(now.year, now.month, now.day);
    _selectedDate = _today;
  }

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year.toString().padLeft(4, '0')}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String get _ymd {
    final d = _selectedDate;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  int get _price =>
      (widget.venue.pricePerHour * _durationMin / 60).round();

  bool _slotFree(int startHour, Map<String, VenueSlot> occupied) {
    for (var minute = 0; minute < _durationMin; minute += 30) {
      final total = startHour * 60 + minute;
      final hh = (total ~/ 60).toString().padLeft(2, '0');
      final mm = (total % 60).toString().padLeft(2, '0');
      if (occupied.containsKey('${_dateKey}_$hh$mm')) return false;
    }
    return true;
  }

  bool _inPast(int startHour) {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      startHour,
    );
    return !start.isAfter(_nowKigali);
  }

  bool _canStart(int startHour, Map<String, VenueSlot> occupied) =>
      startHour * 60 + _durationMin <= 22 * 60 &&
      !_inPast(startHour) &&
      _slotFree(startHour, occupied);

  String? _reasonForDisabled(
    int startHour,
    Map<String, VenueSlot> occupied,
  ) {
    if (startHour * 60 + _durationMin > 22 * 60) return 'Closes 10 PM';
    if (_inPast(startHour)) return 'Past';
    if (!_slotFree(startHour, occupied)) return 'Booked';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<BookingRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your slot')),
      body: StreamBuilder<Map<String, VenueSlot>>(
        stream: repository.watchDaySlots(widget.venue.id, _dateKey),
        builder: (context, snapshot) {
          final occupied = snapshot.data ?? const <String, VenueSlot>{};
          if (_selectedStart != null) {
            final hour = int.tryParse(_selectedStart!.split(':').first) ?? 0;
            if (!_canStart(hour, occupied)) _selectedStart = null;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _VenueSummary(venue: widget.venue),
              const SizedBox(height: 20),
              const _Label('Pick a date'),
              const SizedBox(height: 8),
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = _today.add(Duration(days: index));
                    final selected = DateUtils.isSameDay(date, _selectedDate);
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() {
                        _selectedDate = date;
                        _selectedStart = null;
                      }),
                      child: Container(
                        width: 62,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              index == 0
                                  ? 'Today'
                                  : _weekdays[date.weekday - 1],
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.headings,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _months[date.month - 1],
                              style: TextStyle(
                                color: selected
                                    ? Colors.white70
                                    : AppColors.secondaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              const _Label('Duration'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final duration in _durations)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: duration == _durations.last ? 0 : 8,
                        ),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                duration == 60
                                    ? '1 hour'
                                    : duration == 90
                                        ? '1.5 hours'
                                        : '2 hours',
                              ),
                            ),
                          ),
                          selected: _durationMin == duration,
                          onSelected: (_) => setState(() {
                            _durationMin = duration;
                            _selectedStart = null;
                          }),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _durationMin == duration
                                ? Colors.white
                                : AppColors.secondaryText,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(child: _Label('Start time')),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.35,
                ),
                itemCount: 15,
                itemBuilder: (context, index) {
                  final hour = 7 + index;
                  final start = '${hour.toString().padLeft(2, '0')}:00';
                  final enabled = _canStart(hour, occupied);
                  final selected = _selectedStart == start;
                  final reason = _reasonForDisabled(hour, occupied);
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: enabled
                        ? () => setState(() => _selectedStart = start)
                        : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : enabled
                                ? AppColors.surface
                                : AppColors.border.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formatTime12h(start),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : enabled
                                      ? AppColors.headings
                                      : AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (reason != null && !selected)
                            Text(
                              reason,
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 9,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Slots are held for 10 minutes while you complete payment. '
                'Late cancellations (within 2 hours of kickoff) are not refunded.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatRwf(_price),
                    style: const TextStyle(
                      color: AppColors.headings,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _selectedStart == null || _submitting
                        ? null
                        : _confirm,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _selectedStart == null
                                ? 'Select a start time'
                                : 'Continue · ${formatTime12h(_selectedStart!)}',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final start = _selectedStart;
    if (start == null) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm booking',
              style: TextStyle(
                color: AppColors.headings,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            _SummaryRow(label: 'Pitch', value: widget.venue.name),
            _SummaryRow(
              label: 'Date',
              value:
                  '${formatDateLong(_selectedDate)} · ${formatTime12h(start)}',
            ),
            _SummaryRow(
              label: 'Duration',
              value: '$_durationMin minutes',
            ),
            _SummaryRow(label: 'Total', value: formatRwf(_price)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm booking'),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      final result = await context.read<BookingRepository>().createBooking(
            venueId: widget.venue.id,
            date: _ymd,
            startTime: start,
            durationMin: _durationMin,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BookingConfirmationScreen(
            bookingId: result.bookingId,
            justBooked: true,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
        setState(() {
          _submitting = false;
          _selectedStart = null;
        });
      }
    }
  }
}

class _VenueSummary extends StatelessWidget {
  const _VenueSummary({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.darkContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            venue.sport == Sport.basketball
                ? Icons.sports_basketball
                : Icons.sports_soccer,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venue.name,
                style: const TextStyle(
                  color: AppColors.headings,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${venue.sector.label} · ${formatRwf(venue.pricePerHour)}/hr',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.headings,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

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
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.headings,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
