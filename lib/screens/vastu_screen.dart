import 'package:flutter/material.dart';
import '../theme.dart';

class VastuScreen extends StatelessWidget {
  const VastuScreen({super.key});

  static const _rules = <String, Map<String, dynamic>>{
    'Monday': {
      'planet': 'Moon', 'energy': 'Calm / nurturing',
      'best': 'North-West', 'bestActivity': 'Planning and family activities',
      'avoid': 'South-East', 'avoidActivity': 'Major confrontational decisions',
      'sleep': 'South', 'work': 'North', 'eat': 'East', 'study': 'North-East',
      'tips': ['Keep the home calm and uncluttered.', 'Use the day for planning and reflection.'],
    },
    'Tuesday': {
      'planet': 'Mars', 'energy': 'Action / drive',
      'best': 'South', 'bestActivity': 'Physical work and execution',
      'avoid': 'North-East', 'avoidActivity': 'Starting delicate negotiations',
      'sleep': 'South', 'work': 'South', 'eat': 'East', 'study': 'North-East',
      'tips': ['Keep entrances clear.', 'Prefer decisive, organized work.'],
    },
    'Wednesday': {
      'planet': 'Mercury', 'energy': 'Learning / communication',
      'best': 'North', 'bestActivity': 'Study and communication',
      'avoid': 'South-West', 'avoidActivity': 'Unnecessary disputes',
      'sleep': 'South', 'work': 'North', 'eat': 'East', 'study': 'North-East',
      'tips': ['Keep the study/work area organized.', 'Use the day for learning and communication.'],
    },
    'Thursday': {
      'planet': 'Jupiter', 'energy': 'Growth / wisdom',
      'best': 'North-East', 'bestActivity': 'Learning and spiritual work',
      'avoid': 'South-West', 'avoidActivity': 'Cluttered storage',
      'sleep': 'South', 'work': 'North', 'eat': 'East', 'study': 'North-East',
      'tips': ['Keep the north-east area clean.', 'Prefer learning and long-term planning.'],
    },
    'Friday': {
      'planet': 'Venus', 'energy': 'Harmony / relationships',
      'best': 'South-East', 'bestActivity': 'Creative and social activities',
      'avoid': 'South-West', 'avoidActivity': 'Heavy clutter',
      'sleep': 'South', 'work': 'North', 'eat': 'East', 'study': 'North-East',
      'tips': ['Keep living spaces pleasant.', 'Use the day for harmony and creative work.'],
    },
    'Saturday': {
      'planet': 'Saturn', 'energy': 'Discipline / structure',
      'best': 'West', 'bestActivity': 'Maintenance and organization',
      'avoid': 'North-East', 'avoidActivity': 'Impulsive decisions',
      'sleep': 'South', 'work': 'West', 'eat': 'East', 'study': 'North-East',
      'tips': ['Clear unused items.', 'Focus on maintenance and organization.'],
    },
    'Sunday': {
      'planet': 'Sun', 'energy': 'Vitality / leadership',
      'best': 'East', 'bestActivity': 'Leadership and planning',
      'avoid': 'West', 'avoidActivity': 'Passive work',
      'sleep': 'South', 'work': 'East', 'eat': 'East', 'study': 'North-East',
      'tips': ['Keep the east side bright and open.', 'Use the day for planning and leadership.'],
    },
  };

  @override
  Widget build(BuildContext context) {
    final weekday = const [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ][DateTime.now().weekday - 1];
    final data = _rules[weekday]!;

    final tips = List<String>.from(data['tips'] as List);

    return Scaffold(
      appBar: AppBar(title: const Text('Vastu')),
      body: RefreshIndicator(
        onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 200)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(weekday, style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.maroon)),
                  const SizedBox(height: 4),
                  Text('Ruling planet: ${data['planet']}'),
                  Text('Energy: ${data['energy']}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _directionCard('Best direction', data['best'], data['bestActivity'], Icons.check_circle_outline),
            const SizedBox(height: 10),
            _directionCard('Avoid direction', data['avoid'], data['avoidActivity'], Icons.do_not_disturb_alt_outlined),
            const SizedBox(height: 12),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily directions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _row('Sleeping', data['sleep']),
                  _row('Working', data['work']),
                  _row('Eating', data['eat']),
                  _row('Study', data['study']),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tips', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  ...tips.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('• ', style: TextStyle(color: AppColors.maroon)),
                      Expanded(child: Text(t)),
                    ]),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _directionCard(String title, String direction, String activity, IconData icon) {
    return InfoCard(
      child: Row(children: [
        Icon(icon, color: AppColors.maroon, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(direction, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text(activity, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ]),
  );
}
