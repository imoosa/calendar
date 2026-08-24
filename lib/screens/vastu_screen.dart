import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

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

  Future<void> _refresh() async {
    setState(() => _future = _api.fetchVastuToday());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vastu'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Could not load Vastu: ${snap.error}'));
            }

            final data = snap.data ?? {};
            if (data['enabled'] != true) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: InfoCard(
                      child: Text(
                        'Vastu guidance is currently unavailable from the server.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }

            final tips = (data['tips'] as List<dynamic>? ?? [])
                .map((e) => '$e')
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['weekday'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.maroon,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Ruling planet: ${data['ruling_planet'] ?? '—'}'),
                      Text('Energy: ${data['energy_type'] ?? '—'}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _directionCard(
                  'Best direction',
                  data['best_direction'],
                  data['best_activity'],
                  Icons.check_circle_outline,
                ),
                const SizedBox(height: 10),
                _directionCard(
                  'Avoid direction',
                  data['avoid_direction'],
                  data['avoid_activity'],
                  Icons.do_not_disturb_alt_outlined,
                ),
                const SizedBox(height: 12),
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily directions',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      _simpleRow('Sleeping', data['sleeping_direction']),
                      _simpleRow('Working', data['working_direction']),
                      _simpleRow('Eating', data['eating_direction']),
                      _simpleRow('Study', data['study_direction']),
                    ],
                  ),
                ),
                if (tips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tips',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 7),
                        ...tips.map(
                          (tip) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppColors.maroon)),
                                Expanded(child: Text(tip)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _directionCard(
    String title,
    dynamic direction,
    dynamic activity,
    IconData icon,
  ) {
    return InfoCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.maroon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  '${direction ?? '—'}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                if (activity != null)
                  Text(
                    '$activity',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Text(
            '${value ?? '—'}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
