import 'package:flutter/material.dart';
import '../models/today_data.dart';
import '../services/api_service.dart';
import '../services/home_widget_service.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _api = ApiService();
  late Future<TodayData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TodayData> _load() async {
    final data = await _api.fetchToday();
    // Keep the home-screen widget in sync every time the app is opened.
    await HomeWidgetService.pushToWidget(data);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<TodayData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('Could not load today: ${snap.error}')),
                ],
              );
            }
            final data = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(data.locationName, style: Theme.of(context).textTheme.bodyMedium),
                if (data.native != null)
                  Text(
                    '${data.native!.day} ${data.native!.monthName} ${data.native!.year} · ${data.native!.calendarLabel}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFB5121B),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _prayerRow('Fajr', data.prayer.fajr, 'Asr', data.prayer.asr),
                        _prayerRow('Zawal', data.prayer.zawal, 'Maghrib', data.prayer.maghrib),
                        const Divider(),
                        Text('Isha  ${data.prayer.isha}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Events', style: Theme.of(context).textTheme.titleMedium),
                if (data.events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No events today.', style: TextStyle(fontStyle: FontStyle.italic)),
                  )
                else
                  ...data.events.map((e) => ListTile(
                        leading: const Icon(Icons.circle, size: 10, color: Color(0xFFB5121B)),
                        title: Text(e.title),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _prayerRow(String l1, String t1, String l2, String t2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(l1)),
          Expanded(child: Text(t1, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(l2)),
          Expanded(child: Text(t2, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
