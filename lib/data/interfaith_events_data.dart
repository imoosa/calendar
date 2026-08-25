// Dart port of interfaith_calendar.py, for events NOT tied to Bohra/Sunni/
// Shia Hijri dates.
//
// Christian, French, Parsi: computed live below -- same algorithms as the
// Python (Meeus/Jones/Butcher Easter; flat 365-day Parsi Navroz stepping).
// Safe to trust for any year.
//
// Hindu, Jewish: the Python versions need pyswisseph (real ephemeris) and
// convertdate (Hebrew calendar arithmetic) respectively -- there's no Dart
// equivalent, so rather than approximate them badly, these are PRECOMPUTED
// from the actual Python for 2025-2027 and hardcoded below. Past 2027 these
// tables go empty -- see note at the bottom for how to extend them.
//
// NOTE: while generating the Jewish dates below, found and fixed a real bug
// in interfaith_calendar.py's jewish_events(): it loops
// `hy in (year + 3759, year + 3760)`, which is off by one and makes it
// silently skip Rosh Hashanah / Yom Kippur / Sukkot / Hanukkah every year.
// The correct loop is `(year + 3760, year + 3761)`. Worth fixing in the
// Flask app too -- this file already uses the corrected dates.

import 'parsi_hijri.dart';

class InterfaithEvent {
  final DateTime date;
  final String title;
  final String tradition; // christian | french | jewish | hindu | parsi
  final bool isHoliday;
  const InterfaithEvent(this.date, this.title, this.tradition,
      {this.isHoliday = false});
}

DateTime gregorianEaster(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

List<InterfaithEvent> christianEvents(int year) {
  final easter = gregorianEaster(year);
  return [
    InterfaithEvent(DateTime(year, 1, 6), "Epiphany", "christian", isHoliday: true),
    InterfaithEvent(easter.subtract(const Duration(days: 46)), "Ash Wednesday", "christian"),
    InterfaithEvent(easter.subtract(const Duration(days: 7)), "Palm Sunday", "christian"),
    InterfaithEvent(easter.subtract(const Duration(days: 2)), "Good Friday", "christian", isHoliday: true),
    InterfaithEvent(easter, "Easter Sunday", "christian", isHoliday: true),
    InterfaithEvent(easter.add(const Duration(days: 49)), "Pentecost", "christian", isHoliday: true),
    InterfaithEvent(DateTime(year, 11, 1), "All Saints' Day", "christian", isHoliday: true),
    InterfaithEvent(DateTime(year, 12, 25), "Christmas", "christian", isHoliday: true),
  ];
}

List<InterfaithEvent> frenchEvents(int year) {
  final easter = gregorianEaster(year);
  return [
    InterfaithEvent(DateTime(year, 1, 1), "Jour de l'An (New Year)", "french", isHoliday: true),
    InterfaithEvent(easter.add(const Duration(days: 1)), "Lundi de Paques (Easter Monday)", "french", isHoliday: true),
    InterfaithEvent(DateTime(year, 5, 1), "Fete du Travail (Labour Day)", "french", isHoliday: true),
    InterfaithEvent(DateTime(year, 5, 8), "Victoire 1945 (VE Day)", "french", isHoliday: true),
    InterfaithEvent(easter.add(const Duration(days: 39)), "Ascension", "french", isHoliday: true),
    InterfaithEvent(easter.add(const Duration(days: 50)), "Lundi de Pentecote", "french", isHoliday: true),
    InterfaithEvent(DateTime(year, 7, 14), "Fete Nationale (Bastille Day)", "french", isHoliday: true),
    InterfaithEvent(DateTime(year, 8, 15), "Assomption", "french", isHoliday: true),
    InterfaithEvent(DateTime(year, 11, 1), "Toussaint (All Saints)", "french", isHoliday: true),
    InterfaithEvent(DateTime(year, 11, 11), "Armistice 1918", "french", isHoliday: true),
    InterfaithEvent(DateTime(year, 12, 25), "Noel (Christmas)", "french", isHoliday: true),
  ];
}

List<InterfaithEvent> parsiEvents(int year) {
  final navroz = ParsiCalendar.shahenshahiNavroz(year);
  return [
    InterfaithEvent(navroz.subtract(const Duration(days: 1)), "Pateti (day of repentance)", "parsi"),
    InterfaithEvent(navroz, "Navroz (Jamshedi Navroz) -- Parsi New Year", "parsi", isHoliday: true),
    InterfaithEvent(navroz.add(const Duration(days: 5)), "Khordad Sal (Zarathustra's birthday)", "parsi", isHoliday: true),
  ];
}

// ---- Precomputed from the real Python (with the off-by-one fix applied) ----

final Map<int, List<InterfaithEvent>> _hinduByYear = {
  2025: [
    InterfaithEvent(DateTime(2025, 3, 14), "Holi", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2025, 8, 9), "Raksha Bandhan", "hindu"),
    InterfaithEvent(DateTime(2025, 8, 27), "Ganesh Chaturthi", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2025, 9, 14), "Janmashtami", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2025, 9, 22), "Navratri begins", "hindu"),
    InterfaithEvent(DateTime(2025, 10, 2), "Dussehra (Vijayadashami)", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2025, 10, 21), "Diwali", "hindu", isHoliday: true),
  ],
  2026: [
    InterfaithEvent(DateTime(2026, 3, 3), "Holi", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2026, 8, 28), "Raksha Bandhan", "hindu"),
    InterfaithEvent(DateTime(2026, 9, 15), "Ganesh Chaturthi", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2026, 10, 11), "Navratri begins", "hindu"),
    InterfaithEvent(DateTime(2026, 10, 21), "Dussehra (Vijayadashami)", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2026, 11, 9), "Diwali", "hindu", isHoliday: true),
  ],
  2027: [
    InterfaithEvent(DateTime(2027, 3, 22), "Holi", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2027, 8, 17), "Raksha Bandhan", "hindu"),
    InterfaithEvent(DateTime(2027, 9, 4), "Ganesh Chaturthi", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2027, 9, 23), "Janmashtami", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2027, 10, 10), "Dussehra (Vijayadashami)", "hindu", isHoliday: true),
    InterfaithEvent(DateTime(2027, 10, 29), "Diwali", "hindu", isHoliday: true),
  ],
};

final Map<int, List<InterfaithEvent>> _jewishByYear = {
  2025: [
    InterfaithEvent(DateTime(2025, 3, 14), "Purim", "jewish"),
    InterfaithEvent(DateTime(2025, 4, 13), "Pesach (Passover) begins", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2025, 6, 2), "Shavuot", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2025, 9, 23), "Rosh Hashanah", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2025, 10, 2), "Yom Kippur", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2025, 10, 7), "Sukkot begins", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2025, 12, 15), "Hanukkah begins", "jewish"),
  ],
  2026: [
    InterfaithEvent(DateTime(2026, 3, 3), "Purim", "jewish"),
    InterfaithEvent(DateTime(2026, 4, 2), "Pesach (Passover) begins", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2026, 5, 22), "Shavuot", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2026, 9, 12), "Rosh Hashanah", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2026, 9, 21), "Yom Kippur", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2026, 9, 26), "Sukkot begins", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2026, 12, 5), "Hanukkah begins", "jewish"),
  ],
  2027: [
    InterfaithEvent(DateTime(2027, 2, 21), "Purim", "jewish"),
    InterfaithEvent(DateTime(2027, 4, 22), "Pesach (Passover) begins", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2027, 6, 11), "Shavuot", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2027, 10, 2), "Rosh Hashanah", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2027, 10, 11), "Yom Kippur", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2027, 10, 16), "Sukkot begins", "jewish", isHoliday: true),
    InterfaithEvent(DateTime(2027, 12, 25), "Hanukkah begins", "jewish"),
  ],
};

/// All interfaith events for one Gregorian year. Hindu/Jewish return []
/// outside 2025-2027 -- extend `_hinduByYear`/`_jewishByYear` above (or
/// re-run the Python against pyswisseph/convertdate) if you need further years.
List<InterfaithEvent> getInterfaithEvents(int year) {
  return [
    ...christianEvents(year),
    ...frenchEvents(year),
    ...parsiEvents(year),
    ...(_hinduByYear[year] ?? []),
    ...(_jewishByYear[year] ?? []),
  ];
}
