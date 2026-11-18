import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/venue.dart';
import '../../repositories/venue_repository.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency.dart';
import '../../utils/ui.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_badge.dart';

class OwnerAddPitchScreen extends StatefulWidget {
  const OwnerAddPitchScreen({super.key});

  @override
  State<OwnerAddPitchScreen> createState() => _OwnerAddPitchScreenState();
}

class _OwnerAddPitchScreenState extends State<OwnerAddPitchScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<SessionController>().uid;
    if (uid == null) return const Scaffold(body: LoadingView());
    final repository = context.read<VenueRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('My pitches')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, uid, null),
        icon: const Icon(Icons.add_business),
        label: const Text('Add pitch'),
      ),
      body: AsyncStreamView<List<Venue>>(
        stream: repository.watchOwnerVenues(uid),
        loadingMessage: 'Loading pitches…',
        builder: (context, venues) {
          if (venues.isEmpty) {
            return EmptyView(
              icon: Icons.stadium_outlined,
              title: 'No pitches yet',
              message:
                  'Publish your first venue with photos, amenities and an hourly price.',
              action: FilledButton.icon(
                onPressed: () => _openForm(context, uid, null),
                icon: const Icon(Icons.add),
                label: const Text('Add your first pitch'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: venues.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final venue = venues[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openForm(context, uid, venue),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      children: [
                        _Thumb(venue: venue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      venue.name,
                                      style: const TextStyle(
                                        color: AppColors.headings,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  StatusBadge(
                                    label: venue.status.name,
                                    tone: venue.status == VenueStatus.active
                                        ? BadgeTone.success
                                        : BadgeTone.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${venue.sport.label} · ${venue.format} · ${venue.sector.label}',
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${formatRwf(venue.pricePerHour)}/hr · ${venue.rating.toStringAsFixed(1)} ★ (${venue.ratingCount})',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    String uid,
    Venue? existing,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _VenueFormScreen(uid: uid, existing: existing),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    if (venue.photos.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          venue.photos.first,
          width: 62,
          height: 62,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.darkContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.stadium, color: AppColors.accent),
    );
  }
}

class _VenueFormScreen extends StatefulWidget {
  const _VenueFormScreen({required this.uid, required this.existing});

  final String uid;
  final Venue? existing;

  @override
  State<_VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends State<_VenueFormScreen> {
  static const _formats = ['5-a-side', '7-a-side', '11-a-side', 'Full court', '3x3'];
  static const _surfaces = [
    'Artificial turf',
    'Natural grass',
    'Concrete',
    'Indoor wood',
  ];
  static const _amenityOptions = [
    'Floodlights',
    'Changing rooms',
    'Parking',
    'Seating',
    'Scoreboard',
    'Showers',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _price;
  late Sport _sport;
  late String _format;
  late String _surface;
  late KigaliSector _sector;
  late Set<String> _amenities;
  late bool _active;
  final _picker = ImagePicker();
  final List<XFile> _newPhotos = [];
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final venue = widget.existing;
    _name = TextEditingController(text: venue?.name ?? '');
    _address = TextEditingController(text: venue?.address ?? '');
    _price = TextEditingController(
      text: venue == null ? '' : '${venue.pricePerHour}',
    );
    _sport = venue?.sport ?? Sport.football;
    _format = venue?.format ?? _formats[1];
    _surface = venue?.surface ?? _surfaces.first;
    _sector = venue?.sector == KigaliSector.all
        ? KigaliSector.remera
        : venue?.sector ?? KigaliSector.remera;
    _amenities = {...?venue?.amenities};
    _active = venue?.status != VenueStatus.inactive;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingPhotos = widget.existing?.photos ?? const <String>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add pitch' : 'Edit pitch'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Pitch name'),
              validator: (value) => (value ?? '').trim().length < 2
                  ? 'Enter a pitch name'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Sport>(
                    initialValue: _sport,
                    decoration: const InputDecoration(labelText: 'Sport'),
                    items: [
                      for (final sport in Sport.values)
                        DropdownMenuItem(
                          value: sport,
                          child: Text(sport.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _sport = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _format,
                    decoration: const InputDecoration(labelText: 'Format'),
                    items: [
                      for (final format in _formats)
                        DropdownMenuItem(value: format, child: Text(format)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _format = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _surface,
              decoration: const InputDecoration(labelText: 'Surface'),
              items: [
                for (final surface in _surfaces)
                  DropdownMenuItem(value: surface, child: Text(surface)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _surface = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<KigaliSector>(
              initialValue: _sector,
              decoration: const InputDecoration(labelText: 'Sector'),
              items: [
                for (final sector in KigaliSector.values)
                  if (sector != KigaliSector.all)
                    DropdownMenuItem(value: sector, child: Text(sector.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sector = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Address / landmark',
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Add a street address or landmark'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price per hour (RWF)',
                prefixText: 'RWF ',
              ),
              validator: (value) {
                final n = int.tryParse((value ?? '').trim());
                if (n == null || n <= 0) return 'Enter an hourly price';
                return null;
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Amenities',
              style: TextStyle(
                color: AppColors.headings,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amenity in _amenityOptions)
                  FilterChip(
                    label: Text(amenity),
                    selected: _amenities.contains(amenity),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _amenities.add(amenity);
                      } else {
                        _amenities.remove(amenity);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Photos',
                    style: TextStyle(
                      color: AppColors.headings,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (existingPhotos.isEmpty && _newPhotos.isEmpty)
              Container(
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Add up to 4 photos of the pitch.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              )
            else
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final url in existingPhotos)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: 120,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 120,
                              color: AppColors.border,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    for (var i = 0; i < _newPhotos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FutureBuilder(
                                future: _newPhotos[i].readAsBytes(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Container(
                                      width: 120,
                                      height: 90,
                                      color: AppColors.border,
                                    );
                                  }
                                  return Image.memory(
                                    snapshot.data!,
                                    width: 120,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(
                                  () => _newPhotos.removeAt(i),
                                ),
                                child: const CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Visible to players',
                style: TextStyle(
                  color: AppColors.headings,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text('Turn off to hide this pitch from search.'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isNew ? 'Publish pitch' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final existingCount = widget.existing?.photos.length ?? 0;
    final remaining = 4 - existingCount - _newPhotos.length;
    if (remaining <= 0) return;
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 82);
      if (!mounted) return;
      setState(() {
        _newPhotos.addAll(picked.take(remaining));
      });
    } catch (error) {
      if (mounted) showAppError(context, error);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final repository = context.read<VenueRepository>();
    final existing = widget.existing;
    try {
      final venue = Venue(
        id: existing?.id ?? '',
        ownerId: widget.uid,
        name: _name.text.trim(),
        sport: _sport,
        format: _format,
        surface: _surface,
        sector: _sector,
        address: _address.text.trim(),
        pricePerHour: int.parse(_price.text.trim()),
        amenities: _amenities.toList(growable: false),
        photos: existing?.photos ?? const [],
        rating: existing?.rating ?? 0,
        ratingCount: existing?.ratingCount ?? 0,
        status: _active ? VenueStatus.active : VenueStatus.inactive,
      );
      final venueId =
          existing?.id ?? await repository.createVenue(venue, widget.uid);
      final uploaded = <String>[];
      for (final photo in _newPhotos) {
        final bytes = await photo.readAsBytes();
        final url = await repository.uploadVenuePhoto(
          venueId: venueId,
          bytes: bytes,
          contentType: photo.mimeType ?? 'image/jpeg',
        );
        uploaded.add(url);
      }
      if (uploaded.isNotEmpty) {
        final updated = Venue(
          id: venueId,
          ownerId: venue.ownerId,
          name: venue.name,
          sport: venue.sport,
          format: venue.format,
          surface: venue.surface,
          sector: venue.sector,
          address: venue.address,
          pricePerHour: venue.pricePerHour,
          amenities: venue.amenities,
          photos: [...venue.photos, ...uploaded],
          rating: venue.rating,
          ratingCount: venue.ratingCount,
          status: venue.status,
        );
        await repository.updateVenue(updated);
      } else if (existing != null) {
        await repository.updateVenue(venue);
      }
      if (!mounted) return;
      showAppSuccess(
        context,
        _isNew ? 'Pitch published.' : 'Pitch updated.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
        setState(() => _saving = false);
      }
    }
  }
}
