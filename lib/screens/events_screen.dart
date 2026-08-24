import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    final now = DateTime.now();
    return _api.fetchGeneralEvents(
      start: now,
      end: now.add(const Duration(days: 30)),
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
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Could not load events: ${snap.error}'));
            }

            final days = snap.data?['days'] as List<dynamic>? ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _filterBar(),
                const SizedBox(height: 10),
                ..._buildDays(days),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterBar() {
    const values = [
      'All',
      'Bohra',
      'Sunni',
      'Shia',
      'Christian',
      'Jewish',
      'Hindu',
      'Parsi',
      'French',
    ];

    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: values.map((value) {
            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: ChoiceChip(
                label: Text(value, style: const TextStyle(fontSize: 11)),
                selected: _filter == value,
                onSelected: (_) => setState(() => _filter = value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildDays(List<dynamic> days) {
    final result = <Widget>[];

    for (final raw in days) {
      if (raw is! Map) continue;
      final day = Map<String, dynamic>.from(raw);
      final events = <Map<String, dynamic>>[];

      for (final key in ['hijri_events', 'interfaith_events']) {
        final list = day[key];
        if (list is List) {
          for (final e in list) {
            if (e is Map) {
              final item = Map<String, dynamic>.from(e);
              if (_matches(item)) events.add(item);
            }
          }
        }
      }

      if (events.isEmpty) continue;

      result.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InfoCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, dd MMM yyyy').format(
                    DateTime.parse('${day['date']}'),
                  ),
                  style: const TextStyle(
                    color: AppColors.maroon,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (day['hijri'] is Map)
                  Text(
                    '${day['hijri']['month_name']} ${day['hijri']['day']}, ${day['hijri']['year']}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 6),
                ...events.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: _color(e),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e['title'] ?? ''}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (e['description'] != null)
                                Text(
                                  '${e['description']}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (result.isEmpty) {
      return [
        const InfoCard(
          child: Text(
            'No events match this filter in the next 30 days.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      ];
    }

    return result;
  }

  bool _matches(Map<String, dynamic> event) {
    if (_filter == 'All') return true;

    final source = '${event['event_source'] ?? event['source'] ?? ''}'.toLowerCase();
    final target = _filter.toLowerCase();

    if (source == target) return true;

    // Some older seeded rows may not expose event_source; use title/context
    // only as a display fallback rather than changing backend data.
    return false;
  }

  Color _color(Map<String, dynamic> event) {
    final explicit = event['color']?.toString();
    if (explicit != null && explicit.isNotEmpty) {
      return parseHexColor(explicit);
    }

    switch ('${event['event_source'] ?? event['source'] ?? ''}'.toLowerCase()) {
      case 'sunni':
        return AppColors.sunni;
      case 'shia':
        return AppColors.shia;
      case 'christian':
        return AppColors.christian;
      case 'jewish':
        return AppColors.jewish;
      case 'hindu':
        return AppColors.hindu;
      case 'parsi':
        return AppColors.parsi;
      case 'french':
        return AppColors.french;
      default:
        return AppColors.bohra;
    }
  }
}
