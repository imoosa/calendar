// Dart port of parsi_calendar.py's date arithmetic (Navroz calculation and
// month/day conversion only -- the Gah/Roj daily-watch functions need
// sunrise/sunset from prayer_times_calc.dart if you want those later).

const List<String> kParsiMonthNames = [
  "Fravardin", "Ardibehesht", "Khordad", "Tir", "Amardad", "Shehrevar",
  "Meher", "Avan", "Adar", "Dae", "Bahman", "Aspandarmad",
];
const int kParsiGathaMonth = 13;

// Same reference date as parsi_calendar.py -- see that module's docstring
// for the calibration caveat (unverified against an official Parsi source).
final DateTime kParsiRefNavroz = DateTime(2026, 8, 16);

class ParsiDate {
  final int year;
  final int month;
  final int day;
  const ParsiDate(this.year, this.month, this.day);
}

class ParsiCalendar {
  static DateTime shahenshahiNavroz(int year) {
    var candidate = kParsiRefNavroz;
    while (candidate.year < year) {
      candidate = candidate.add(const Duration(days: 365));
    }
    while (candidate.year > year) {
      candidate = candidate.subtract(const Duration(days: 365));
    }
    return candidate;
  }

  static String monthName(int month) =>
      month == kParsiGathaMonth ? "Gatha days" : kParsiMonthNames[month - 1];

  static (int, DateTime) _navrozBracketing(DateTime g) {
    int year = g.year;
    var navroz = shahenshahiNavroz(year);
    if (g.isBefore(navroz)) {
      year -= 1;
      navroz = shahenshahiNavroz(year);
    } else {
      final nxt = shahenshahiNavroz(year + 1);
      if (!g.isBefore(nxt)) {
        year += 1;
        navroz = nxt;
      }
    }
    return (year, navroz);
  }

  static ParsiDate gregorianToParsi(DateTime g) {
    final (year, navroz) = _navrozBracketing(g);
    final offset = g.difference(navroz).inDays;
    if (offset < 360) {
      return ParsiDate(year, offset ~/ 30 + 1, offset % 30 + 1);
    }
    return ParsiDate(year, kParsiGathaMonth, offset - 360 + 1);
  }

  static DateTime parsiToGregorian(int year, int month, int day) {
    final navroz = shahenshahiNavroz(year);
    final offset =
        month == kParsiGathaMonth ? 360 + (day - 1) : (month - 1) * 30 + (day - 1);
    return navroz.add(Duration(days: offset));
  }
}
