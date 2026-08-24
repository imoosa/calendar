// lib/screens/events_screen.dart
//
// Lists Hijri + interfaith events for the next 30 days via
// /api/mobile/events. Deliberately does NOT show personal events --
// the backend excludes them from this route on purpose (single-tenant
// PersonalEvent table server-side; see api_service.dart's comment).
// If you want personal events in this app, they need to be stored
// on-device (e.g. sqflite/Hive), not fetched from this endpoint.

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future;

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
      appBar: AppBar(title: const Text('Events')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                const SizedBox(height: 120),
                Center(child: Text('Could not load events: ${snap.error}')),
              ]);
            }
            final days = (snap.data!['days'] as List<dynamic>? ?? []);
            final rows = <Widget>[];
            for (final d in days) {
              final day = d as Map<String, dynamic>;
              final hijriEvents = (day['hijri_events'] as List<dynamic>? ?? []);
              final interfaithEvents = (day['interfaith_events'] as List<dynamic>? ?? []);
              final all = [...hijriEvents, ...interfaithEvents];
              if (all.isEmpty) continue;
              rows.add(Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(day['date'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB5121B))),
              ));
              for (final e in all) {
                final ev = e as Map<String, dynamic>;
                rows.add(ListTile(
                  leading: const Icon(Icons.circle, size: 10, color: Color(0xFFB5121B)),
                  title: Text(ev['title']?.toString() ?? ''),
                  subtitle: ev['description'] != null ? Text(ev['description'].toString()) : null,
                ));
              }
            }
            if (rows.isEmpty) {
              return const Center(child: Text('No events in the next 30 days.'));
            }
            return ListView(children: rows);
          },
        ),
      ),
    );
  }
}
