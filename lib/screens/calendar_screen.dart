// lib/screens/calendar_screen.dart
// Multi-calendar Flutter implementation matching the Samaa web calendar.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _api = ApiService();
  String _calendar = 'hijri';
  String _secondary = 'gregorian';
  DateTime _selected = DateTime.now();
  int? _year;
  int? _month;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load({int? year, int? month, DateTime? selected}) async {
    final prefs = await SharedPreferences.getInstance();
    _calendar = prefs.getString('default_calendar') ?? _calendar;
    _secondary = prefs.getString('secondary_calendar') ?? _secondary;
    final show = <String>[];
    if (prefs.getBool('show_bohra') ?? true) show.add('bohra');
    if (prefs.getBool('show_sunni') ?? true) show.add('sunni');
    if (prefs.getBool('show_shia') ?? true) show.add('shia');
    if (prefs.getBool('show_christian') ?? true) show.add('christian');
    if (prefs.getBool('show_french') ?? true) show.add('french');
    if (prefs.getBool('show_jewish') ?? true) show.add('jewish');
    if (prefs.getBool('show_hindu') ?? true) show.add('hindu');
    if (prefs.getBool('show_parsi') ?? true) show.add('parsi');
    final data = await _api.fetchCalendar(
      calendar: _calendar,
      secondary: _secondary,
      year: year,
      month: month,
      selected: selected ?? _selected,
      show: show,
    );
    final c = data['calendar'] as Map<String, dynamic>;
    _year = (c['year'] as num).toInt();
    _month = (c['month'] as num).toInt();
    return data;
  }

  void reload() => setState(() => _future = _load());

  void _navigate(int year, int month) {
    setState(() {
      _year = year;
      _month = month;
      _future = _load(year: year, month: month, selected: _selected);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _selected = picked;
      _future = _load(selected: picked);
    });
  }

  void _today() {
    final now = DateTime.now();
    setState(() {
      _selected = now;
      _future = _load(selected: now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(onPressed: reload, icon: const Icon(Icons.calendar_today_outlined)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }
          if (snap.hasError) {
            return _ErrorCard(error: snap.error.toString(), onRetry: reload);
          }
          final data = snap.data!;
          final c = data['calendar'] as Map<String, dynamic>;
          final secondary = data['secondary'] as Map<String, dynamic>? ?? {};
          final nav = data['navigation'] as Map<String, dynamic>;
          final weeks = (data['weeks'] as List<dynamic>? ?? []);
          final prayer = data['prayer'] as Map<String, dynamic>?;
          final selected = data['selected'] as Map<String, dynamic>? ?? {};
          final today = data['today'] as Map<String, dynamic>? ?? {};

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
              children: [
                _Toolbar(onDate: _pickDate, onToday: _today),
                const SizedBox(height: 8),
                _MonthHeader(
                  monthName: c['month_name']?.toString() ?? '',
                  year: c['year']?.toString() ?? '',
                  secondaryLabel: secondary['month_label']?.toString() ?? '',
                  onPrevious: () => _navigate((nav['prev_year'] as num).toInt(), (nav['prev_month'] as num).toInt()),
                  onNext: () => _navigate((nav['next_year'] as num).toInt(), (nav['next_month'] as num).toInt()),
                ),
                _WeekdayHeader(),
                _CalendarGrid(
                  weeks: weeks,
                  onSelect: (date) {
                    setState(() {
                      _selected = date;
                      _future = _load(selected: date, year: _year, month: _month);
                    });
                  },
                ),
                if (prayer != null) _PrayerStrip(prayer: prayer, location: (data['location'] as Map<String, dynamic>?)?['name']?.toString() ?? ''),
                if (data['hindu_daily'] != null) _HinduDaily(data['hindu_daily'] as Map<String, dynamic>),
                if (data['hebrew_daily'] != null) _HebrewDaily(data['hebrew_daily'] as Map<String, dynamic>),
                if (data['parsi_daily'] != null) _ParsiDaily(data['parsi_daily'] as Map<String, dynamic>),
                if (data['christian_daily'] != null) _ChristianDaily(data['christian_daily'] as Map<String, dynamic>),
                const SizedBox(height: 14),
                _DayEventsCard(
                  title: 'Selected day',
                  date: selected['date']?.toString() ?? '',
                  events: (selected['events'] as List<dynamic>? ?? []),
                ),
                const SizedBox(height: 12),
                _DayEventsCard(
                  title: 'Today',
                  date: today['date']?.toString() ?? '',
                  events: (today['events'] as List<dynamic>? ?? []),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final VoidCallback onDate;
  final VoidCallback onToday;
  const _Toolbar({required this.onDate, required this.onToday});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _ToolButton(icon: Icons.edit_note, label: 'Note', onTap: () {}),
          const SizedBox(width: 8),
          _ToolButton(icon: Icons.explore_outlined, label: 'Qibla', onTap: () {}),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDate,
              icon: const Icon(Icons.calendar_month, size: 17),
              label: const Text('dd-mm-yyyy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onDate, child: const Text('Go')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onToday, child: const Text('Today')),
        ],
      );
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
}

class _MonthHeader extends StatelessWidget {
  final String monthName;
  final String year;
  final String secondaryLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const _MonthHeader({required this.monthName, required this.year, required this.secondaryLabel, required this.onPrevious, required this.onNext});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            height: 58,
            child: Row(
              children: [
                IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(monthName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.text)),
                      Text(year, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: AppColors.border))),
            child: Text(secondaryLabel, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
        ],
      );
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'
        ].map((d) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Center(child: Text(d, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.text)))))).toList(),
      );
}

class _CalendarGrid extends StatelessWidget {
  final List<dynamic> weeks;
  final ValueChanged<DateTime> onSelect;
  const _CalendarGrid({required this.weeks, required this.onSelect});
  @override
  Widget build(BuildContext context) => Column(
        children: weeks.map((week) {
          final cells = week as List<dynamic>;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells.map((raw) {
              if (raw == null) return const Expanded(child: SizedBox(height: 72));
              final d = raw as Map<String, dynamic>;
              return Expanded(child: _DayCell(data: d, onTap: () => onSelect(DateTime.parse(d['date'].toString()))));
            }).toList(),
          );
        }).toList(),
      );
}

class _DayCell extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _DayCell({required this.data, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final selected = data['is_selected'] == true;
    final today = data['is_today'] == true;
    final events = data['events'] as List<dynamic>? ?? [];
    final primary = data['primary_day']?.toString() ?? '';
    final secondary = data['secondary_day']?.toString();
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0D8) : (today ? const Color(0xFFF0F5F3) : Colors.transparent),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.fromLTRB(7, 7, 5, 4),
        child: Stack(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(primary, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
              if (secondary != null && secondary.isNotEmpty) Text(secondary, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
              if (events.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(spacing: 3, children: events.take(3).map((e) => Container(width: 6, height: 6, decoration: BoxDecoration(color: _eventColor(e), shape: BoxShape.circle))).toList()),
              ],
            ]),
            if (data['is_ekadashi'] == true) const Positioned(right: 4, top: 4, child: _Dot(color: Color(0xFF8E44AD))),
            if (data['is_purnima'] == true) const Positioned(right: 4, top: 4, child: _Dot(color: Color(0xFFE67E22))),
          ],
        ),
      ),
    );
  }

  static Color _eventColor(dynamic raw) {
    final m = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final c = m['color']?.toString();
    if (c != null && c.startsWith('#') && c.length == 7) {
      final value = int.tryParse(c.substring(1), radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return AppColors.maroon;
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _PrayerStrip extends StatelessWidget {
  final Map<String, dynamic> prayer;
  final String location;
  const _PrayerStrip({required this.prayer, required this.location});
  @override
  Widget build(BuildContext context) {
    final items = [
      ['FAJR', prayer['fajr']], ['SUNRISE', prayer['sunrise']], ['ZAWAL', prayer['zawal']],
      ['ZUHR END', prayer['zuhr_end']], ['SUNSET', prayer['sunset']], ['MAGHRIB', prayer['maghrib']],
    ];
    return Column(children: [
      Container(
        margin: const EdgeInsets.only(top: 0),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border), bottom: BorderSide(color: AppColors.border))),
        child: Row(children: items.map((x) => Expanded(child: Column(children: [Text(x[0].toString(), style: const TextStyle(fontSize: 9, color: AppColors.muted)), const SizedBox(height: 2), Text(x[1]?.toString() ?? '--:--', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text))]))).toList()),
      ),
      if (location.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(location, style: const TextStyle(fontSize: 11.5, color: AppColors.muted))),
    ]);
  }
}

class _DayEventsCard extends StatelessWidget {
  final String title;
  final String date;
  final List<dynamic> events;
  const _DayEventsCard({required this.title, required this.date, required this.events});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            if (date.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3, bottom: 10), child: Text(_formatDate(date), style: const TextStyle(fontSize: 12, color: AppColors.muted))),
            if (events.isEmpty) const Text('No events today.', style: TextStyle(fontSize: 13, color: AppColors.muted))
            else ...events.map((e) {
              final m = e as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(margin: const EdgeInsets.only(top: 5, right: 9), width: 7, height: 7, decoration: BoxDecoration(color: _color(m['color']), shape: BoxShape.circle)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['title']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), if (m['description'] != null) Text(m['description'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.muted))])),
                ]),
              );
            }),
          ]),
        ),
      );

  static String _formatDate(String value) {
    try {
      final d = DateTime.parse(value);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return value;
    }
  }
  static Color _color(dynamic value) {
    final c=value?.toString();
    if(c!=null && c.startsWith('#') && c.length==7){final n=int.tryParse(c.substring(1),radix:16);if(n!=null)return Color(0xFF000000|n);}
    return AppColors.maroon;
  }
}

class _HinduDaily extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HinduDaily(this.data);
  @override
  Widget build(BuildContext context) => InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text("Today's Panchang", style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 12),
    Text('Tithi: ${data['tithi']} (${data['paksha']})'),
    Text('Nakshatra: ${data['nakshatra']}'),
    Text('Sunrise: ${data['sunrise']}   Sunset: ${data['sunset']}'),
    Text('Rahu Kalam: ${(data['rahu_kalam'] as Map<String,dynamic>)['start']} - ${(data['rahu_kalam'] as Map<String,dynamic>)['end']}'),
    Text('Abhijit: ${(data['abhijit'] as Map<String,dynamic>)['start']} - ${(data['abhijit'] as Map<String,dynamic>)['end']}'),
  ]));
}

class _HebrewDaily extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HebrewDaily(this.data);
  @override
  Widget build(BuildContext context) => InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text("Shabbat & today's Zmanim", style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 12),
    Text('Sunrise: ${data['sunrise']}   Sunset: ${data['sunset']}'),
    Text('Sof zman tefila: ${data['sof_zman_tefila']}'),
    Text('Shacharit window: ${data['shacharit_time_left'] == true ? 'open' : 'passed'}'),
  ]));
}

class _ParsiDaily extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ParsiDaily(this.data);
  @override
  Widget build(BuildContext context) => InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Roj · Mah · Gah', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 12),
    Text('Roj: ${data['roj']}'), Text('Mah: ${data['month_name']}'), Text('Current Gah: ${data['gah']}'),
  ]));
}

class _ChristianDaily extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ChristianDaily(this.data);
  @override
  Widget build(BuildContext context) => InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Christian liturgical information', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 12), Text('${data['season']} · ${data['color_name']}'),
    if (data['saint'] != null) Text('${(data['saint'] as Map<String,dynamic>)['name']}'),
  ]));
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorCard({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 44, color: AppColors.muted), const SizedBox(height: 12), const Text('Could not load the calendar.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)), const SizedBox(height: 8), Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)), const SizedBox(height: 14), FilledButton(onPressed: onRetry, child: const Text('Retry'))]))));
}
