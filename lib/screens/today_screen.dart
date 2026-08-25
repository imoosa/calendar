import 'package:flutter/material.dart';
import '../models/today_data.dart';
import '../services/home_widget_service.dart';
import '../services/local_calendar_service.dart';
import '../theme.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<TodayData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TodayData> _load() async {
    final data = await LocalCalendarService.todayData();
    await HomeWidgetService.pushToWidget(data);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Samaa'),
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
        child: FutureBuilder<TodayData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.maroon),
              );
            }
            if (snap.hasError) {
              return Center(child: Text('Could not load today: ${snap.error}'));
            }

            final data = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _hero(data),
                const SizedBox(height: 12),
                _prayerCard(data.prayer),
                const SizedBox(height: 12),
                _eventCard(data),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hero(TodayData data) {
    return InfoCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TODAY', style: TextStyle(
            color: AppColors.muted, fontSize: 11,
            fontWeight: FontWeight.w800, letterSpacing: 1.4,
          )),
          const SizedBox(height: 4),
          Text(data.date, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 15, color: AppColors.muted),
            const SizedBox(width: 4),
            Expanded(child: Text(data.locationName,
              style: const TextStyle(fontSize: 13, color: AppColors.muted))),
          ]),
          if (data.native != null) ...[
            const SizedBox(height: 12),
            Text('${data.native!.day} ${data.native!.monthName} ${data.native!.year}',
              style: const TextStyle(fontSize: 24, height: 1.1,
                fontWeight: FontWeight.w800, color: AppColors.maroon)),
            const SizedBox(height: 3),
            Text(data.native!.calendarLabel,
              style: const TextStyle(color: AppColors.muted, fontSize: 12,
                fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _prayerCard(PrayerTimes p) {
    final items = [
      ['Fajr', p.fajr], ['Sunrise', p.sunrise], ['Zawal', p.zawal],
      ['Zuhr End', p.zuhrEnd], ['Sunset', p.sunset], ['Maghrib', p.maghrib],
      ['Isha', p.isha],
    ];
    return InfoCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runSpacing: 14,
        children: items.map((x) => SizedBox(
          width: 78,
          child: Column(children: [
            Text(x[0].toUpperCase(), style: const TextStyle(
              fontSize: 9, color: AppColors.muted)),
            const SizedBox(height: 3),
            Text(x[1], style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _eventCard(TodayData data) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's events", style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (data.events.isEmpty)
            const Text('No events today.',
              style: TextStyle(fontSize: 13, color: AppColors.muted))
          else
            ...data.events.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 5, right: 9),
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: _eventColor(e.source),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Text(e.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
            )),
        ],
      ),
    );
  }

  Color _eventColor(String? source) {
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
