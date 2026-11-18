import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/slot.dart';
import '../../models/venue.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/venue_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import 'owner_add_pitch_screen.dart';

class OwnerAvailabilityScreen extends StatefulWidget {
  const OwnerAvailabilityScreen({super.key});

  @override
  State<OwnerAvailabilityScreen> createState() =>
      _OwnerAvailabilityScreenState();
}

class _OwnerAvailabilityScreenState extends State<OwnerAvailabilityScreen> {
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
  String? _venueId;
  final Set<String> _selectedSlots = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<SessionController>().uid;
    if (uid == null) return const Scaffold(body: LoadingView());
    final venues = context.read<VenueRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Availability')),
      body: AsyncStreamView<List<Venue>>(
        stream: venues.watchOwnerVenues(uid),
        loadingMessage: 'Loading pitches…',
        builder: (context, venueList) {
          if (venueList.isEmpty) {
            return EmptyView(
              icon: Icons.add_business_outlined,
              title: 'Add a pitch first',
              message: 'Availability is managed per pitch.',
              action: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OwnerAddPitchScreen(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add pitch'),
              ),
            );
          }
          _venueId ??= venueList.first.id;
          final selectedVenue = venueList.firstWhere(
            (v) => v.id == _venueId,
            orElse: () => venueList.first,
          );
          _venueId = selectedVenue.id;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedVenue.id,
                  decoration: const InputDecoration(labelText: 'Pitch'),
                  items: [
                    for (final venue in venueList)
                      DropdownMenuItem(
                        value: venue.id,
                        child: Text(venue.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _venueId = value;
                        _selectedSlots.clear();
                      });
                    }
                  },
                ),
              ),
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 7,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = _today.add(Duration(days: index));
                    final selected = DateUtils.isSameDay(date, _selectedDate);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        _selectedDate = date;
                        _selectedSlots.clear();
                      }),
                      child: Container(
                        width: 58,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
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
                                    ? Colors.white70
                                    : AppColors.secondaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.headings,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _months[date.month - 1],
                              style: TextStyle(
                                color: selected
                                    ? Colors.white70
                                    : AppColors.secondaryText,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: StreamBuilder<Map<String, VenueSlot>>(
                  stream: context
                      .read<BookingRepository>()
                      .watchDaySlots(selectedVenue.id, _dateKey),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ErrorView(message: snapshot.error.toString());
                    }
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const LoadingView(message: 'Loading slots…');
                    }
                    final slots = snapshot.data ?? const <String, VenueSlot>{};
                    final allIds = [
                      for (var hour = 7; hour < 22; hour++)
                        for (final minute in [0, 30])
                          '${_dateKey}_${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}',
                    ];
                    return Column(
                      children: [
                        const _Legend(),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 7,
                              crossAxisSpacing: 7,
                              childAspectRatio: 2.25,
                            ),
                            itemCount: allIds.length,
                            itemBuilder: (context, index) {
                              final id = allIds[index];
                              final slot = slots[id];
                              final booked = slot?.isBooked ?? false;
                              final blocked = slot?.isBlocked ?? false;
                              final selected = _selectedSlots.contains(id);
                              final hour = index ~/ 2 + 7;
                              final minute = index.isEven ? '00' : '30';
                              return InkWell(
                                borderRadius: BorderRadius.circular(9),
                                onTap: booked
                                    ? null
                                    : () => setState(() {
                                          if (selected) {
                                            _selectedSlots.remove(id);
                                          } else {
                                            _selectedSlots.add(id);
                                          }
                                        }),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: booked
                                        ? AppColors.border
                                        : blocked
                                            ? AppColors.warning.withValues(
                                                alpha: 0.18,
                                              )
                                            : selected
                                                ? AppColors.primary
                                                : AppColors.surface,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : booked
                                              ? AppColors.border
                                              : blocked
                                                  ? AppColors.warning
                                                  : AppColors.border,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatTime12h(
                                          '${hour.toString().padLeft(2, '0')}:$minute',
                                        ),
                                        style: TextStyle(
                                          color: booked
                                              ? AppColors.secondaryText
                                              : selected
                                                  ? Colors.white
                                                  : AppColors.headings,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (booked || blocked)
                                        Text(
                                          booked ? 'Booked' : 'Blocked',
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white70
                                                : AppColors.secondaryText,
                                            fontSize: 8,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _selectedSlots.isEmpty || _busy
                                        ? null
                                        : () => _apply(selectedVenue, false),
                                    child: const Text('Unblock'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _selectedSlots.isEmpty || _busy
                                        ? null
                                        : () => _apply(selectedVenue, true),
                                    child: Text(
                                      _selectedSlots.isEmpty
                                          ? 'Select slots'
                                          : 'Block ${_selectedSlots.length}',
                                    ),
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
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _apply(Venue venue, bool block) async {
    String? reason;
    if (block) {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Block these slots?'),
          content: TextField(
            controller: controller,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Maintenance, private event…',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Block'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      reason = controller.text.trim();
    }
    setState(() => _busy = true);
    try {
      final result = await context.read<BookingRepository>().setSlotBlocked(
            venueId: venue.id,
            date: _ymd,
            slotIds: _selectedSlots.toList(growable: false),
            blocked: block,
            reason: reason?.isEmpty ?? true ? null : reason,
          );
      if (!mounted) return;
      showAppSuccess(
        context,
        '${result.changed} slot${result.changed == 1 ? '' : 's'} ${block ? 'blocked' : 'unblocked'}.',
      );
      setState(() {
        _busy = false;
        _selectedSlots.clear();
      });
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
        setState(() => _busy = false);
      }
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          _LegendDot(color: AppColors.surface, label: 'Free'),
          SizedBox(width: 12),
          _LegendDot(color: AppColors.warning, label: 'Blocked'),
          SizedBox(width: 12),
          _LegendDot(color: AppColors.border, label: 'Booked'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
