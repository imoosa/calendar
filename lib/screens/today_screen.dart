import 'package:flutter/material.dart';
import '../models/today_data.dart';
import '../services/api_service.dart';
import '../services/home_widget_service.dart';
import '../theme.dart';

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
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<TodayData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.maroon),
              );
            }
            if (snap.hasError) {
              return _error(snap.error);
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
          const Text(
            'TODAY',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.date,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  data.locationName,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
            ],
          ),
          if (data.native != null) ...[
            const SizedBox(height: 12),
            Text(
              '${data.native!.day} ${data.native!.monthName} ${data.native!.year}',
              style: const TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: AppColors.maroon,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.native!.calendarLabel,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _prayerCard(PrayerTimes p) {
    return InfoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Prayer Times',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          _prayerRow('Fajr', p.fajr, 'Asr', p.asr),
          _prayerRow('Zawal', p.zawal, 'Maghrib', p.maghrib),
          _prayerRow('Sunrise', p.sunrise, 'Sunset', p.sunset),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              'Isha   ${p.isha}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prayerRow(String a, String av, String b, String bv) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(a, style: const TextStyle(color: AppColors.muted))),
          Expanded(
            child: Text(av, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(b, style: const TextStyle(color: AppColors.muted))),
          Expanded(
            child: Text(bv, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(TodayData data) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Today\'s events',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${data.events.length}',
                style: const TextStyle(
                  color: AppColors.maroon,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (data.events.isEmpty)
            const Text(
              'No events today.',
              style: TextStyle(
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...data.events.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: parseHexColor(e.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        e.title,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _error(Object? error) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Padding(
          padding: const EdgeInsets.all(24),
          child: InfoCard(
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 38, color: AppColors.muted),
                const SizedBox(height: 12),
                const Text(
                  'Could not connect to Samaa Calendar.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '$error',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => setState(() => _future = _load()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
