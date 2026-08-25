// lib/screens/calendar_screen.dart
// Fully offline rewrite -- no network calls. Bohra/Sunni/Shia/Parsi/Gregorian
// month grids are computed locally via bohra_hijri.dart / umm_al_qura_hijri.dart
// / parsi_hijri.dart. Hebrew and Hindu calendars fall back to a Gregorian
// grid (their real month math needs libraries with no Dart equivalent --
// see interfaith_events_data.dart's header for why).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../data/bohra_hijri.dart';
import '../data/umm_al_qura_hijri.dart';
import '../data/parsi_hijri.dart';
import '../data/hijri_events_data.dart';
import '../data/interfaith_events_data.dart';
import '../data/prayer_times_calc.dart';

// Default location -- mirrors the Flask app's fallback (Mumbai) since this
// build has no location picker yet. Wire this to a real location/settings
// value later if you add one.
const double _kDefaultLat = 19.076;
const double _kDefaultLng = 72.877;
const double _kDefaultTzOffset = 5.5;
const String _kDefaultLocationName = 'Mumbai, Maharashtra';

class _EventOut {
  final String title;
  final String source; // bohra|sunni|shia|christian|french|jewish|hindu|parsi
  final bool isHoliday;
  final bool isFastingDay;
  const _EventOut(this.title, this.source, this.isHoliday, this.isFastingDay);
}

Color _sourceColor(String source) {
  switch (source) {
    case 'bohra':
      return AppColors.bohra;
    case 'sunni':
      return AppColors.sunni;
    case 'shia':
      return AppColors.shia;
    case 'christian':
      return AppColors.christian;
    case 'french':
      return AppColors.french;
    case 'jewish':
      return AppColors.jewish;
    case 'hindu':
      return AppColors.hindu;
    case 'parsi':
      return AppColors.parsi;
    default:
      return AppColors.bohra;
  }
}

class _DayCellData {
  final DateTime gregorian;
  final String primaryLabel;
  final String? secondaryLabel;
  final bool isToday;
  final bool isSelected;
  final List<_EventOut> events;
  _DayCellData({
    required this.gregorian,
    required this.primaryLabel,
    this.secondaryLabel,
    required this.isToday,
    required this.isSelected,
    required this.events,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _calendar = 'hijri';
  String _secondary = 'gregorian';
  Set<String> _enabledSources = {
    'bohra', 'sunni', 'shia', 'christian', 'jewish', 'hindu', 'parsi', 'french'
  };

  late int _year;
  late int _month;
  DateTime _selected = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _calendar = prefs.getString('default_calendar') ?? 'hijri';
    _secondary = prefs.getString('secondary_calendar') ?? 'gregorian';
    _enabledSources = {
      if (prefs.getBool('show_bohra') ?? true) 'bohra',
      if (prefs.getBool('show_sunni') ?? true) 'sunni',
      if (prefs.getBool('show_shia') ?? true) 'shia',
      if (prefs.getBool('show_christian') ?? true) 'christian',
      if (prefs.getBool('show_jewish') ?? true) 'jewish',
      if (prefs.getBool('show_hindu') ?? true) 'hindu',
      if (prefs.getBool('show_parsi') ?? true) 'parsi',
      if (prefs.getBool('show_french') ?? true) 'french',
    };

    final effectiveCal = _effectiveCalendar(_calendar);
    final now = DateTime.now();
    final (y, m) = _primaryYearMonthFor(effectiveCal, now);
    setState(() {
      _year = y;
      _month = m;
      _loading = false;
    });
  }

  // Hebrew/Hindu aren't ported offline -- fall back to Gregorian.
  String _effectiveCalendar(String cal) =>
      (cal == 'hebrew' || cal == 'hindu') ? 'gregorian' : cal;

  (int, int) _primaryYearMonthFor(String cal, DateTime g) {
    switch (cal) {
      case 'hijri':
        final h = BohraHijri.gregorianToHijri(g);
        return (h.year, h.month);
      case 'sunni':
      case 'shia':
        final h = UmmAlQuraHijri.gregorianToHijri(g);
        return (h.year, h.month);
      case 'parsi':
        final p = ParsiCalendar.gregorianToParsi(g);
        return (p.year, p.month);
      default: // gregorian
        return (g.year, g.month);
    }
  }

  void _navigate(int deltaMonths) {
    final cal = _effectiveCalendar(_calendar);
    setState(() {
      for (int i = 0; i < deltaMonths.abs(); i++) {
        final forward = deltaMonths > 0;
        if (cal == 'parsi') {
          if (forward) {
            if (_month == kParsiGathaMonth) {
              _year += 1;
              _month = 1;
            } else if (_month == 12) {
              _month = kParsiGathaMonth;
            } else {
              _month += 1;
            }
          } else {
            if (_month == 1) {
              _year -= 1;
              _month = kParsiGathaMonth;
            } else if (_month == kParsiGathaMonth) {
              _month = 12;
            } else {
              _month -= 1;
            }
          }
        } else {
          if (forward) {
            if (_month == 12) {
              _year += 1;
              _month = 1;
            } else {
              _month += 1;
            }
          } else {
            if (_month == 1) {
              _year -= 1;
              _month = 12;
            } else {
              _month -= 1;
            }
          }
        }
      }
    });
  }

  void _goToday() {
    final cal = _effectiveCalendar(_calendar);
    final now = DateTime.now();
    final (y, m) = _primaryYearMonthFor(cal, now);
    setState(() {
      _selected = now;
      _year = y;
      _month = m;
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
    final cal = _effectiveCalendar(_calendar);
    final (y, m) = _primaryYearMonthFor(cal, picked);
    setState(() {
      _selected = picked;
      _year = y;
      _month = m;
    });
  }

  int _monthLength(String cal, int year, int month) {
    switch (cal) {
      case 'hijri':
        return BohraHijri.monthLength(year, month);
      case 'sunni':
      case 'shia':
        return UmmAlQuraHijri.monthLength(year, month);
      case 'parsi':
        return month == kParsiGathaMonth ? 5 : 30;
      default:
        return DateTime(year, month + 1, 0).day;
    }
  }

  DateTime _gregorianFor(String cal, int year, int month, int day) {
    switch (cal) {
      case 'hijri':
        return BohraHijri.hijriToGregorian(year, month, day);
      case 'sunni':
      case 'shia':
        return UmmAlQuraHijri.hijriToGregorian(year, month, day);
      case 'parsi':
        return ParsiCalendar.parsiToGregorian(year, month, day);
      default:
        return DateTime(year, month, day);
    }
  }

  String _monthName(String cal, int year, int month) {
    switch (cal) {
      case 'hijri':
        return BohraHijri.monthName(month);
      case 'sunni':
      case 'shia':
        return UmmAlQuraHijri.monthName(month);
      case 'parsi':
        return ParsiCalendar.monthName(month);
      default:
        const g = [
          'January','February','March','April','May','June',
          'July','August','September','October','November','December'
        ];
        return g[month - 1];
    }
  }

  String? _secondaryLabel(DateTime g) {
    final sec = _secondary;
    if (sec.isEmpty) return null;
    switch (sec) {
      case 'gregorian':
        return '${g.day}';
      case 'hijri':
        return '${BohraHijri.gregorianToHijri(g).day}';
      case 'sunni':
      case 'shia':
        return '${UmmAlQuraHijri.gregorianToHijri(g).day}';
      case 'parsi':
        return '${ParsiCalendar.gregorianToParsi(g).day}';
      default:
        return null; // hebrew/hindu secondary not ported offline
    }
  }

  final Map<int, List<InterfaithEvent>> _interfaithCache = {};

  List<_EventOut> _eventsFor(DateTime g) {
    final out = <_EventOut>[];

    final bh = BohraHijri.gregorianToHijri(g);
    if (_enabledSources.contains('bohra')) {
      for (final e in bohraEvents) {
        if (e.month == bh.month && e.day == bh.day) {
          out.add(_EventOut(e.title, 'bohra', e.isHoliday, e.isFastingDay));
        }
      }
    }

    final uq = UmmAlQuraHijri.gregorianToHijri(g);
    if (_enabledSources.contains('sunni')) {
      for (final e in sunniEvents) {
        if (e.month == uq.month && e.day == uq.day) {
          out.add(_EventOut(e.title, 'sunni', e.isHoliday, e.isFastingDay));
        }
      }
    }
    if (_enabledSources.contains('shia')) {
      for (final e in shiaEvents) {
        if (e.month == uq.month && e.day == uq.day) {
          out.add(_EventOut(e.title, 'shia', e.isHoliday, e.isFastingDay));
        }
      }
    }

    final interfaith =
        _interfaithCache.putIfAbsent(g.year, () => getInterfaithEvents(g.year));
    for (final ie in interfaith) {
      if (ie.date.year == g.year &&
          ie.date.month == g.month &&
          ie.date.day == g.day &&
          _enabledSources.contains(ie.tradition)) {
        out.add(_EventOut(ie.title, ie.tradition, ie.isHoliday, false));
      }
    }

    return out;
  }

  List<List<_DayCellData?>> _buildWeeks(String cal, int year, int month) {
    final length = _monthLength(cal, year, month);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final cells = <_DayCellData?>[];
    for (int d = 1; d <= length; d++) {
      final g = _gregorianFor(cal, year, month, d);
      final gDay = DateTime(g.year, g.month, g.day);
      final label = (cal == 'hijri') ? BohraHijri.toArabicIndicNumerals(d) : '$d';
      cells.add(_DayCellData(
        gregorian: gDay,
        primaryLabel: label,
        secondaryLabel: _secondary == cal ? null : _secondaryLabel(gDay),
        isToday: gDay == today,
        isSelected: gDay ==
            DateTime(_selected.year, _selected.month, _selected.day),
        events: _eventsFor(gDay),
      ));
    }

    if (cells.isEmpty) return [];
    final firstWeekday = cells.first!.gregorian.weekday % 7; // Sun=0..Sat=6
    final leading = List<_DayCellData?>.filled(firstWeekday, null);
    final all = [...leading, ...cells];
    final trailing = (7 - all.length % 7) % 7;
    all.addAll(List<_DayCellData?>.filled(trailing, null));

    final weeks = <List<_DayCellData?>>[];
    for (int i = 0; i < all.length; i += 7) {
      weeks.add(all.sublist(i, i + 7));
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.maroon)));
    }

    final cal = _effectiveCalendar(_calendar);
    final weeks = _buildWeeks(cal, _year, _month);
    final monthName = _monthName(cal, _year, _month);

    final gSelected = DateTime(_selected.year, _selected.month, _selected.day);
    final gToday = DateTime.now();
    final gTodayOnly = DateTime(gToday.year, gToday.month, gToday.day);

    // Secondary label for the header: the Gregorian range this primary
    // month spans, when secondary == gregorian (most common case).
    String secondaryHeaderLabel = '';
    if (_secondary == 'gregorian' && weeks.isNotEmpty) {
      DateTime? firstG, lastG;
      for (final w in weeks) {
        for (final c in w) {
          if (c == null) continue;
          firstG ??= c.gregorian;
          lastG = c.gregorian;
        }
      }
      if (firstG != null && lastG != null) {
        const g = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        final a = '${g[firstG.month - 1]} ${firstG.year}';
        final b = '${g[lastG.month - 1]} ${lastG.year}';
        secondaryHeaderLabel = a == b ? a : '$a / $b';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.calendar_today_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
        children: [
          if (_calendar == 'hebrew' || _calendar == 'hindu')
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LocationWarningBanner(
                locationName:
                    "${_calendar == 'hebrew' ? 'Hebrew' : 'Hindu'} calendar isn't available offline yet -- showing Gregorian",
              ),
            ),
          Row(
            children: [
              OutlinedButton(onPressed: _pickDate, child: const Text('Pick date')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _goToday, child: const Text('Today')),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              SizedBox(
                height: 58,
                child: Row(
                  children: [
                    IconButton(onPressed: () => _navigate(-1), icon: const Icon(Icons.chevron_left)),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(monthName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                          Text('$_year', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => _navigate(1), icon: const Icon(Icons.chevron_right)),
                  ],
                ),
              ),
              if (secondaryHeaderLabel.isNotEmpty)
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border.symmetric(horizontal: BorderSide(color: AppColors.border)),
                  ),
                  child: Text(secondaryHeaderLabel, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
            ],
          ),
          Row(
            children: ['SUN','MON','TUE','WED','THU','FRI','SAT']
                .map((d) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Center(
                          child: Text(d, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ))
                .toList(),
          ),
          ...weeks.map((week) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: week.map((cell) {
                  if (cell == null) return const Expanded(child: SizedBox(height: 72));
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selected = cell.gregorian),
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: cell.isSelected
                              ? const Color(0xFFFFF0D8)
                              : (cell.isToday ? const Color(0xFFF0F5F3) : Colors.transparent),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.fromLTRB(7, 7, 5, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cell.primaryLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            if (cell.secondaryLabel != null)
                              Text(cell.secondaryLabel!, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                            if (cell.events.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 3,
                                children: cell.events.take(3).map((e) {
                                  return Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(color: _sourceColor(e.source), shape: BoxShape.circle),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )),
          if (cal == 'hijri' || cal == 'sunni' || cal == 'shia') ...[
            const SizedBox(height: 14),
            _prayerStrip(),
          ],
          if (cal == 'parsi') ...[
            const SizedBox(height: 14),
            _parsiStrip(gToday),
          ],
          const SizedBox(height: 14),
          _dayEventsCard('Selected day', gSelected),
          const SizedBox(height: 12),
          _dayEventsCard('Today', gTodayOnly),
        ],
      ),
    );
  }

  Widget _prayerStrip() {
    final p = calculatePrayerTimes(_kDefaultLat, _kDefaultLng, DateTime.now(), _kDefaultTzOffset);
    final items = [
      ['FAJR', p.fajr], ['SUNRISE', p.sunrise], ['ZAWAL', p.zawal],
      ['ZUHR END', p.zuhrEnd], ['SUNSET', p.sunset], ['MAGHRIB', p.maghrib],
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border), bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: items
                .map((x) => Expanded(
                      child: Column(
                        children: [
                          Text(x[0], style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                          const SizedBox(height: 2),
                          Text(x[1], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(_kDefaultLocationName, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ),
      ],
    );
  }

  Widget _parsiStrip(DateTime today) {
    final p = ParsiCalendar.gregorianToParsi(today);
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Roj · Mah', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text('Mah (month): ${ParsiCalendar.monthName(p.month)}'),
          Text('Day: ${p.day}'),
        ],
      ),
    );
  }

  Widget _dayEventsCard(String title, DateTime date) {
    final events = _eventsFor(date);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateLabel = '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 10),
              child: Text(dateLabel, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
            if (events.isEmpty)
              const Text('No events today.', style: TextStyle(fontSize: 13, color: AppColors.muted))
            else
              ...events.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5, right: 9),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(color: _sourceColor(e.source), shape: BoxShape.circle),
                        ),
                        Expanded(
                          child: Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
