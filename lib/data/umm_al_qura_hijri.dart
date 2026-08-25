// Dart port of sunni_calendar.py's Umm al-Qura tabular calendar. Shared by
// both Sunni and Shia tabs -- shia_calendar.py explicitly reuses the same
// conversion functions as Sunni, only the event tables differ.

import 'bohra_hijri.dart' show HijriDate;

const Set<int> kUmmAlQuraLeapYears = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29};

const List<String> kUmmAlQuraMonthNames = [
  "Muharram", "Safar", "Rabi' al-Awwal",
  "Rabi' al-Akhir", "Jumada al-Ula", "Jumada al-Akhirah",
  "Rajab", "Sha'ban", "Ramadan",
  "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah",
];

// Same epoch/calibration as the Bohra table (sunni_calendar.py imports
// these from hijri_calendar.py directly rather than redefining them).
const int _kEpochJd = 1948440;
const int _kCalibrationOffset = -1;

class UmmAlQuraHijri {
  static bool _isLeap(int year) {
    final pos = ((year - 1) % 30) + 1;
    return kUmmAlQuraLeapYears.contains(pos);
  }

  static int _yearLength(int year) => _isLeap(year) ? 355 : 354;

  static int _monthLength(int year, int month) {
    if (month == 12 && _isLeap(year)) return 30;
    return month % 2 == 1 ? 30 : 29;
  }

  static int hijriToJd(int year, int month, int day) {
    int jd = _kEpochJd + _kCalibrationOffset;
    jd += (year - 1) * 354;
    for (int y = 1; y < year; y++) {
      if (_isLeap(y)) jd += 1;
    }
    for (int m = 1; m < month; m++) {
      jd += _monthLength(year, m);
    }
    jd += day - 1;
    return jd;
  }

  static HijriDate jdToHijri(int jd) {
    jd -= (_kEpochJd + _kCalibrationOffset);
    int year = 1;
    while (true) {
      final yl = _yearLength(year);
      if (jd < yl) break;
      jd -= yl;
      year += 1;
    }
    int month = 1;
    while (true) {
      final ml = _monthLength(year, month);
      if (jd < ml) break;
      jd -= ml;
      month += 1;
    }
    return HijriDate(year, month, jd + 1);
  }

  static int gregorianToJd(DateTime g) {
    final a = (14 - g.month) ~/ 12;
    final y = g.year + 4800 - a;
    final m = g.month + 12 * a - 3;
    return g.day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
  }

  static DateTime jdToGregorian(int jd) {
    final a = jd + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime(year, month, day);
  }

  static HijriDate gregorianToHijri(DateTime g) => jdToHijri(gregorianToJd(g));

  static DateTime hijriToGregorian(int year, int month, int day) =>
      jdToGregorian(hijriToJd(year, month, day));

  static String monthName(int month) => kUmmAlQuraMonthNames[month - 1];

  static int monthLength(int year, int month) => _monthLength(year, month);
}
