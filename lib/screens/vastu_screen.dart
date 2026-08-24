// lib/screens/vastu_screen.dart
//
// Field names copied 1:1 from api_vastu_today()'s jsonify(...) call in
// main.py -- ruling_planet, energy_type, best_direction, etc. Update
// this if that endpoint's shape ever changes.

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VastuScreen extends StatefulWidget {
  const VastuScreen({super.key});
  @override
  State<VastuScreen> createState() => _VastuScreenState();
}

class _VastuScreenState extends State<VastuScreen> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchVastuToday();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vastu')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load Vastu guidance: ${snap.error}'));
          }
          final data = snap.data!;
          if (data['enabled'] != true) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Vastu guidance is turned off in your account settings.'),
              ),
            );
          }
          final tips = (data['tips'] as List<dynamic>? ?? []).cast<String>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${data['weekday']}', style: Theme.of(context).textTheme.titleLarge),
              Text('Ruling planet: ${data['ruling_planet']}'),
              Text('Energy: ${data['energy_type']}'),
              const Divider(height: 32),
              _row('Best direction', data['best_direction'], data['best_activity']),
              _row('Avoid direction', data['avoid_direction'], data['avoid_activity']),
              const Divider(height: 32),
              _row('Sleeping', data['sleeping_direction'], null),
              _row('Working', data['working_direction'], null),
              _row('Eating', data['eating_direction'], null),
              _row('Study', data['study_direction'], null),
              if (tips.isNotEmpty) ...[
                const Divider(height: 32),
                Text('Tips', style: Theme.of(context).textTheme.titleMedium),
                ...tips.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $t'),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, dynamic direction, dynamic activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            activity != null ? '$direction — $activity' : '$direction',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
