import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _api = ApiService();

  int? _hijriYear;
  int? _hijriMonth;
  Map<String, dynamic>? _hijriData;
  Map<String, dynamic>? _generalData;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  String? _error;

  final Set<String> _enabledSources = {
    'bohra',
    'sunni',
    'shia',
    'christian',
    'french',
    'jewish',
    'hindu',
    'parsi',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final today = await _api.fetchHijriToday();
      _hijriYear = today['hijri_year'] as int?;
      _hijriMonth = today['hijri_month'] as int?;

      final first = DateTime(_month.year, _month.month, 1);
      final last = DateTime(_month.year, _month.month + 1, 0);

      final results = await Future.wait([
        _api.fetchHijriMonth(_hijriYear!, _hijriMonth!),
        _api.fetchGeneralEvents(start: first, end: last),
      ]);

      if (!mounted) return;
      setState(() {
        _hijriData = results[0] as Map<String, dynamic>;
        _generalData = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                final now = DateTime.now();
                _month = DateTime(now.year, now.month);
              });
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.maroon))
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    children: [
                      _monthHeader(),
                      const SizedBox(height: 10),
                      _filters(),
                      const SizedBox(height: 10),
                      _calendarGrid(),
                      const SizedBox(height: 14),
                      _selectedMonthEvents(),
                    ],
                  ),
                ),
    );
  }

  Widget _monthHeader() {
    return InfoCard(
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_month),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_hijriData != null)
                  Text(
                    '${_hijriData!['hijri_month_name'] ?? ''} ${_hijriData!['hijri_year'] ?? ''}',
                    style: const TextStyle(
                      color: AppColors.maroon,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    final labels = {
      'bohra': 'Bohra',
      'sunni': 'Sunni',
      'shia': 'Shia',
      'christian': 'Christian',
      'jewish': 'Jewish',
      'hindu': 'Hindu',
      'parsi': 'Parsi',
      'french': 'French',
    };

    return InfoCard(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Wrap(
        spacing: 5,
        runSpacing: 3,
        children: labels.entries.map((entry) {
          final active = _enabledSources.contains(entry.key);
          return FilterChip(
            label: Text(entry.value, style: const TextStyle(fontSize: 11)),
            selected: active,
            onSelected: (value) {
              setState(() {
                if (value) {
                  _enabledSources.add(entry.key);
                } else {
                  _enabledSources.remove(entry.key);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _calendarGrid() {
    final first = DateTime(_month.year, _month.month, 1);
    final last = DateTime(_month.year, _month.month + 1, 0);
    final leading = first.weekday % 7;
    final total = leading + last.day;

    final generalByDate = <String, List<Map<String, dynamic>>>{};
    final days = (_generalData?['days'] as List<dynamic>? ?? []);

    for (final raw in days) {
      if (raw is! Map) continue;
      final day = Map<String, dynamic>.from(raw);
      final date = '${day['date']}';
      final events = <Map<String, dynamic>>[];

      for (final key in ['hijri_events', 'interfaith_events']) {
        final list = day[key];
        if (list is List) {
          for (final e in list) {
            if (e is Map) events.add(Map<String, dynamic>.from(e));
          }
        }
      }
      generalByDate[date] = events;
    }

    final todayKey = _iso(DateTime.now());

    return InfoCard(
      padding: const EdgeInsets.fromLTRB(7, 10, 7, 8),
      child: Column(
        children: [
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 7),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: total,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: .72,
            ),
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox();

              final dayNumber = index - leading + 1;
              final date = DateTime(_month.year, _month.month, dayNumber);
              final key = _iso(date);
              final events = generalByDate[key] ?? [];
              final visibleEvents = events.where(_eventVisible).toList();
              final isToday = key == todayKey;

              return InkWell(
                onTap: () => _showDay(date, visibleEvents),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  padding: const EdgeInsets.fromLTRB(3, 4, 3, 2),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.maroon.withValues(alpha: .08) : null,
                    border: Border.all(
                      color: isToday ? AppColors.maroon : AppColors.border,
                      width: isToday ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                          color: isToday ? AppColors.maroon : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ...visibleEvents.take(2).map(
                            (e) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: _eventColor(e).withValues(alpha: .9),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${e['title'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      if (visibleEvents.length > 2)
                        Text(
                          '+${visibleEvents.length - 2}',
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _eventVisible(Map<String, dynamic> e) {
    final source = '${e['event_source'] ?? e['source'] ?? ''}'.toLowerCase();
    if (source.isEmpty) return true;
    return _enabledSources.contains(source);
  }

  Color _eventColor(Map<String, dynamic> e) {
    final source = '${e['event_source'] ?? e['source'] ?? ''}'.toLowerCase();
    final explicit = e['color']?.toString();
    if (explicit != null && explicit.isNotEmpty) {
      return parseHexColor(explicit);
    }

    switch (source) {
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

  Widget _selectedMonthEvents() {
    final days = (_generalData?['days'] as List<dynamic>? ?? []);
    final rows = <Widget>[];

    for (final raw in days) {
      if (raw is! Map) continue;
      final d = Map<String, dynamic>.from(raw);
      final visible = <Map<String, dynamic>>[];

      for (final key in ['hijri_events', 'interfaith_events']) {
        final list = d[key];
        if (list is List) {
          for (final e in list) {
            if (e is Map) {
              final item = Map<String, dynamic>.from(e);
              if (_eventVisible(item)) visible.add(item);
            }
          }
        }
      }

      if (visible.isEmpty) continue;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: InfoCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, dd MMM yyyy').format(
                    DateTime.parse('${d['date']}'),
                  ),
                  style: const TextStyle(
                    color: AppColors.maroon,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                ...visible.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _eventColor(e),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${e['title'] ?? ''}'),
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

    if (rows.isEmpty) {
      return const InfoCard(
        child: Text(
          'No visible events in this month.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return Column(children: rows);
  }

  void _showDay(DateTime date, List<Map<String, dynamic>> events) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            children: [
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(date),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (events.isEmpty)
                const Text(
                  'No visible events on this date.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                ...events.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 5,
                      backgroundColor: _eventColor(e),
                    ),
                    title: Text('${e['title'] ?? ''}'),
                    subtitle: e['description'] == null
                        ? null
                        : Text('${e['description']}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: InfoCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 36, color: AppColors.muted),
              const SizedBox(height: 10),
              Text(
                'Could not load the calendar.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }

  String _iso(DateTime d) => DateTime(d.year, d.month, d.day)
      .toIso8601String()
      .substring(0, 10);
}
