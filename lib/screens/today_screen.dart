// lib/screens/today_screen.dart
//
// Matches widget_today.html's layout: date line -> big maroon native-date
// line -> bordered prayer table (Fajr/Asr row, Zawal/Maghrib row, Isha
// centered+bold in its own row) -> dotted events list.

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
      appBar: AppBar(title: const Text('TODAY')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<TodayData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.maroon, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.date, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                        Text(data.locationName, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        if (data.native != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${data.native!.day} ${data.native!.monthName} ${data.native!.year} · ${data.native!.calendarLabel}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.maroon,
                                height: 1.2,
                              ),
                            ),
                          ),
                        _prayerTable(data.prayer),
                        const SizedBox(height: 10),
                        _eventsList(data.events),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _prayerTable(PrayerTimes p) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _prayerRow('Fajr', p.fajr, 'Asr', p.asr),
          _prayerRow('Zawal', p.zawal, 'Maghrib', p.maghrib),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, style: BorderStyle.solid)),
            ),
            alignment: Alignment.center,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Isha  ', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                TextSpan(
                  text: p.isha,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prayerRow(String l1, String t1, String l2, String t2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(l1, style: const TextStyle(fontSize: 14, color: AppColors.muted))),
          Expanded(
              child:
                  Text(t1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text))),
          const SizedBox(width: 12),
          Expanded(child: Text(l2, style: const TextStyle(fontSize: 14, color: AppColors.muted))),
          Expanded(
              child:
                  Text(t2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text))),
        ],
      ),
    );
  }

  Widget _eventsList(List<EventItem> events) {
    if (events.isEmpty) {
      return const Text('No events today.', style: TextStyle(fontSize: 13, color: AppColors.muted, fontStyle: FontStyle.italic));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: _parseColor(e.color), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.title, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.maroon;
    try {
      var h = hex.replaceFirst('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return AppColors.maroon;
    }
  }
}
