import 'package:shared_preferences/shared_preferences.dart';

import '../data/bohra_hijri.dart';
import '../data/umm_al_qura_hijri.dart';
import '../data/parsi_hijri.dart';
import '../data/hijri_events_data.dart';
import '../data/interfaith_events_data.dart';
import '../data/prayer_times_calc.dart';
import '../models/today_data.dart';

const double kSamaaDefaultLat = 19.076;
const double kSamaaDefaultLng = 72.877;
const double kSamaaDefaultTz = 5.5;
const String kSamaaDefaultLocation = 'Mumbai, Maharashtra';

class LocalEvent {
  final DateTime date;
  final String title;
  final String source;
  final bool isHoliday;
  final bool isFasting;

  const LocalEvent(
    this.date,
    this.title,
    this.source, {
    this.isHoliday = false,
    this.isFasting = false,
  });

  EventItem toEventItem() => EventItem(
        title: title,
        source: source,
        isHoliday: isHoliday,
        isFasting: isFasting,
      );
}

class LocalCalendarService {
  static Future<Set<String>> enabledSources() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      if (prefs.getBool('show_bohra') ?? true) 'bohra',
      if (prefs.getBool('show_sunni') ?? true) 'sunni',
      if (prefs.getBool('show_shia') ?? true) 'shia',
      if (prefs.getBool('show_christian') ?? true) 'christian',
      if (prefs.getBool('show_jewish') ?? true) 'jewish',
      if (prefs.getBool('show_hindu') ?? true) 'hindu',
      if (prefs.getBool('show_parsi') ?? true) 'parsi',
      if (prefs.getBool('show_french') ?? true) 'french',
    };
  }

  static Future<String> defaultCalendar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('default_calendar') ?? 'hijri';
  }

  static Future<String> secondaryCalendar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('secondary_calendar') ?? 'gregorian';
  }

  static String effectiveCalendar(String cal) =>
      (cal == 'hebrew' || cal == 'hindu') ? 'gregorian' : cal;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static NativeCalendarData nativeFor(DateTime g, String calendar) {
    switch (calendar) {
      case 'hijri':
        final h = BohraHijri.gregorianToHijri(g);
        return NativeCalendarData(
          calendarLabel: 'Bohra (Fatimid) Hijri',
          monthName: BohraHijri.monthName(h.month),
          day: h.day,
          year: h.year,
        );
      case 'sunni':
        final h = UmmAlQuraHijri.gregorianToHijri(g);
        return NativeCalendarData(
          calendarLabel: 'Sunni (Umm al-Qura) Hijri',
          monthName: UmmAlQuraHijri.monthName(h.month),
          day: h.day,
          year: h.year,
        );
      case 'shia':
        final h = UmmAlQuraHijri.gregorianToHijri(g);
        return NativeCalendarData(
          calendarLabel: 'Shia (Jafari) Hijri',
          monthName: UmmAlQuraHijri.monthName(h.month),
          day: h.day,
          year: h.year,
        );
      case 'parsi':
        final p = ParsiCalendar.gregorianToParsi(g);
        return NativeCalendarData(
          calendarLabel: 'Parsi (Shahenshahi)',
          monthName: ParsiCalendar.monthName(p.month),
          day: p.day,
          year: p.year,
        );
      case 'hebrew':
        return NativeCalendarData(
          calendarLabel: 'Hebrew',
          monthName: _gregorianMonth(g.month),
          day: g.day,
          year: g.year,
        );
      case 'hindu':
        return NativeCalendarData(
          calendarLabel: 'Hindu (Lunar)',
          monthName: _gregorianMonth(g.month),
          day: g.day,
          year: g.year,
        );
      default:
        return NativeCalendarData(
          calendarLabel: 'Gregorian',
          monthName: _gregorianMonth(g.month),
          day: g.day,
          year: g.year,
        );
    }
  }

  static String secondaryDay(DateTime g, String secondary) {
    switch (secondary) {
      case 'hijri':
        return '${BohraHijri.gregorianToHijri(g).day}';
      case 'sunni':
      case 'shia':
        return '${UmmAlQuraHijri.gregorianToHijri(g).day}';
      case 'parsi':
        return '${ParsiCalendar.gregorianToParsi(g).day}';
      case 'gregorian':
        return '${g.day}';
      default:
        return '${g.day}';
    }
  }

  static List<LocalEvent> eventsFor(DateTime date, Set<String> enabled) {
    final g = dateOnly(date);
    final out = <LocalEvent>[];

    if (enabled.contains('bohra')) {
      final h = BohraHijri.gregorianToHijri(g);
      for (final e in bohraEvents) {
        if (e.month == h.month && e.day == h.day) {
          out.add(LocalEvent(g, e.title, 'bohra',
              isHoliday: e.isHoliday, isFasting: e.isFastingDay));
        }
      }
    }

    final u = UmmAlQuraHijri.gregorianToHijri(g);
    if (enabled.contains('sunni')) {
      for (final e in sunniEvents) {
        if (e.month == u.month && e.day == u.day) {
          out.add(LocalEvent(g, e.title, 'sunni',
              isHoliday: e.isHoliday, isFasting: e.isFastingDay));
        }
      }
    }

    if (enabled.contains('shia')) {
      for (final e in shiaEvents) {
        if (e.month == u.month && e.day == u.day) {
          out.add(LocalEvent(g, e.title, 'shia',
              isHoliday: e.isHoliday, isFasting: e.isFastingDay));
        }
      }
    }

    final interfaith = getInterfaithEvents(g.year);
    for (final e in interfaith) {
      if (dateOnly(e.date) == g && enabled.contains(e.tradition)) {
        out.add(LocalEvent(g, e.title, e.tradition, isHoliday: e.isHoliday));
      }
    }

    return out;
  }

  static Future<TodayData> todayData() async {
    final now = dateOnly(DateTime.now());
    final cal = await defaultCalendar();
    final enabled = await enabledSources();
    final native = nativeFor(now, cal);
    final p = calculatePrayerTimes(
      kSamaaDefaultLat,
      kSamaaDefaultLng,
      now,
      kSamaaDefaultTz,
    );

    final localEvents = eventsFor(now, enabled);
    final items = localEvents.map((e) => e.toEventItem()).toList();

    final hijriItems =
        items.where((e) => e.source == 'bohra' || e.source == 'sunni' || e.source == 'shia').toList();
    final interfaithItems =
        items.where((e) => e.source != 'bohra' && e.source != 'sunni' && e.source != 'shia').toList();

    return TodayData(
      date: _dateLabel(now),
      native: native,
      prayer: PrayerTimes(
        fajr: p.fajr,
        sunrise: p.sunrise,
        dhuhr: p.zawal,
        asr: p.asr,
        zuhrEnd: p.zuhrEnd,
        sunset: p.sunset,
        maghrib: p.maghrib,
        isha: p.isha,
        zawal: p.zawal,
      ),
      events: items,
      hijriEvents: hijriItems,
      interfaithEvents: interfaithItems,
      personalEvents: const [],
      locationName: kSamaaDefaultLocation,
    );
  }

  static List<LocalEvent> eventsBetween(
    DateTime start,
    DateTime end,
    Set<String> enabled,
  ) {
    var d = dateOnly(start);
    final last = dateOnly(end);
    final result = <LocalEvent>[];

    while (!d.isAfter(last)) {
      result.addAll(eventsFor(d, enabled));
      d = d.add(const Duration(days: 1));
    }
    return result;
  }

  static String _dateLabel(DateTime d) =>
      '${_weekday(d.weekday)}, ${d.day.toString().padLeft(2, '0')} ${_gregorianMonth(d.month)} ${d.year}';

  static String _weekday(int w) =>
      const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][w - 1];

  static String _gregorianMonth(int m) =>
      const ['January','February','March','April','May','June','July','August','September','October','November','December'][m - 1];
}
