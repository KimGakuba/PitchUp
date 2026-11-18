import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/venue.dart';
import '../../repositories/venue_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/async_views.dart';
import '../../widgets/venue_card.dart';
import 'pitch_details_screen.dart';

class ExplorePitchesScreen extends StatefulWidget {
  const ExplorePitchesScreen({super.key});

  @override
  State<ExplorePitchesScreen> createState() => _ExplorePitchesScreenState();
}

class _ExplorePitchesScreenState extends State<ExplorePitchesScreen> {
  final _search = TextEditingController();
  Sport? _sport;
  KigaliSector _sector = KigaliSector.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<VenueRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore pitches'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by pitch, sector or address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All sports',
                  selected: _sport == null,
                  onTap: () => setState(() => _sport = null),
                ),
                for (final sport in Sport.values)
                  _FilterChip(
                    label: sport.label,
                    selected: _sport == sport,
                    onTap: () => setState(() => _sport = sport),
                  ),
                const SizedBox(width: 8),
                for (final sector in KigaliSector.values)
                  _FilterChip(
                    label: sector.label,
                    selected: _sector == sector,
                    onTap: () => setState(() => _sector = sector),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncStreamView<List<Venue>>(
              stream: repository.watchVenues(),
              loadingMessage: 'Finding pitches…',
              builder: (context, venues) {
                final query = _search.text.trim().toLowerCase();
                final filtered = venues.where((venue) {
                  if (_sport != null && venue.sport != _sport) return false;
                  if (_sector != KigaliSector.all && venue.sector != _sector) {
                    return false;
                  }
                  if (query.isEmpty) return true;
                  return venue.name.toLowerCase().contains(query) ||
                      venue.address.toLowerCase().contains(query) ||
                      venue.sector.label.toLowerCase().contains(query) ||
                      venue.format.toLowerCase().contains(query);
                }).toList(growable: false);

                if (filtered.isEmpty) {
                  return const EmptyView(
                    icon: Icons.search_off,
                    title: 'No pitches match',
                    message: 'Try a different sport, sector or search term.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final venue = filtered[index];
                    return VenueCard(
                      venue: venue,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PitchDetailsScreen(venueId: venue.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.secondaryText,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
