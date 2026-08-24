// lib/screens/calendar_screen.dart
//
// Bohra Hijri month grid only, matching what /api/calendar/month/<y>/<m>
// actually returns server-side (see api_service.dart's comment on that
// route). If you want Sunni/Shia/interfaith events layered onto this
// same grid, they need a separate fetchGeneralEvents() call merged in
// client-side -- the server route doesn't include them.

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _api = ApiService();
  int? _year;
  int? _month;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadInitial();
  }

  Future<Map<String, dynamic>> _loadInitial() async {
    final today = await _api.fetchHijriToday();
    _year = today['hijri_year'] as int;
    _month = today['hijri_month'] as int;
    return _api.fetchHijriMonth(_year!, _month!);
  }

  void _goToMonth(int year, int month) {
    // Hijri months are 1-12; roll over into the adjacent year rather
    // than asking the server for an invalid month number.
    if (month < 1) {
      year -= 1;
      month = 12;
    } else if (month > 12) {
      year += 1;
      month = 1;
    }
    setState(() {
      _year = year;
      _month = month;
      _future = _api.fetchHijriMonth(year, month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load calendar: ${snap.error}'));
          }
          final data = snap.data!;
          final days = data['days'] as List<dynamic>? ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _goToMonth(_year!, _month! - 1),
                    ),
                    Text(
                      '${data['hijri_month_name']} ${data['hijri_year']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _goToMonth(_year!, _month! + 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, i) {
                    final day = days[i] as Map<String, dynamic>;
                    final events = day['events'] as List<dynamic>? ?? [];
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${day['hijri_day']}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (events.isNotEmpty)
                            const Icon(Icons.circle, size: 6, color: Color(0xFFB5121B)),
                        ],
                      ),
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
}
