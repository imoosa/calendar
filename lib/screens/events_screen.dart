import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/local_calendar_service.dart';
import '../theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _filter = 'All';
  late Future<List<LocalEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<LocalEvent>> _load() async {
    final enabled = await LocalCalendarService.enabledSources();
    final now = LocalCalendarService.dateOnly(DateTime.now());
    return LocalCalendarService.eventsBetween(
      now,
      now.add(const Duration(days: 30)),
      enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = _load()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _future = _load());
          await _future;
        },
        child: FutureBuilder<List<LocalEvent>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Could not load events: ${snap.error}'));
            }

            final events = (snap.data ?? [])
                .where((e) => _matches(e))
                .toList();

            final grouped = <DateTime, List<LocalEvent>>{};
            for (final event in events) {
              final d = LocalCalendarService.dateOnly(event.date);
              grouped.putIfAbsent(d, () => []).add(event);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _filterBar(),
                const SizedBox(height: 10),
                if (grouped.isEmpty)
                  const InfoCard(
                    child: Text('No events found for the next 30 days.',
                      style: TextStyle(color: AppColors.muted)),
                  )
                else
                  ...grouped.entries.map(_dayCard),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _matches(LocalEvent e) {
    if (_filter == 'All') return true;
    final key = _filter.toLowerCase();
    return e.source == key;
  }

  Widget _filterBar() {
    const values = [
      'All','Bohra','Sunni','Shia','Christian','Jewish','Hindu','Parsi','French'
    ];
    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: values.map((value) => Padding(
            padding: const EdgeInsets.only(right: 5),
            child: ChoiceChip(
              label: Text(value, style: const TextStyle(fontSize: 11)),
              selected: _filter == value,
              onSelected: (_) => setState(() => _filter = value),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _dayCard(MapEntry<DateTime, List<LocalEvent>> entry) {
    final date = entry.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InfoCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, dd MMM yyyy').format(date),
              style: const TextStyle(
                color: AppColors.maroon,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            ...entry.value.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: _color(e.source),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _color(String source) {
    switch (source) {
      case 'sunni': return AppColors.sunni;
      case 'shia': return AppColors.shia;
      case 'christian': return AppColors.christian;
      case 'jewish': return AppColors.jewish;
      case 'hindu': return AppColors.hindu;
      case 'parsi': return AppColors.parsi;
      case 'french': return AppColors.french;
      default: return AppColors.bohra;
    }
  }
}
