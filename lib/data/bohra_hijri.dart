// Dart port of hijri_calendar.py -- Bohra (Fatimid) tabular Hijri calendar.
// Same LEAP_YEARS / EPOCH_JD / CALIBRATION_OFFSET as the Python source.
// If you ever recalibrate the Python side, mirror the change here too.

const int kBohraEpochJd = 1948440;
const int kBohraCalibrationOffset = -1;

const Set<int> kBohraLeapYears = {2, 5, 8, 10, 13, 16, 19, 21, 24, 27, 29};

const List<String> kBohraMonthNames = [
  "Moharram al-Haraam", "Safar al-Muzaffar", "Rabi al-Awwal",
  "Rabi al-Aakhar", "Jumada al-Ula", "Jumada al-Ukhra",
  "Rajab al-Asab", "Shabaan al-Karim", "Ramadaan al-Moazzam",
  "Shawwal al-Mukarram", "Zilqadah al-Haraam", "Zilhaj al-Haraam",
];

class HijriDate {
  final int year;
  final int month; // 1-12
  final int day;
  const HijriDate(this.year, this.month, this.day);
}

class BohraHijri {
  static bool _isLeap(int year) {
    final pos = ((year - 1) % 30) + 1;
    return kBohraLeapYears.contains(pos);
  }

  static int _yearLength(int year) => _isLeap(year) ? 355 : 354;

  static int _monthLength(int year, int month) {
    if (month == 12 && _isLeap(year)) return 30;
    return month % 2 == 1 ? 30 : 29;
  }

  static int hijriToJd(int year, int month, int day) {
    int jd = kBohraEpochJd + kBohraCalibrationOffset;
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
    jd -= (kBohraEpochJd + kBohraCalibrationOffset);
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
    final day = jd + 1;
    return HijriDate(year, month, day);
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

  static String monthName(int month) => kBohraMonthNames[month - 1];

  static int monthLength(int year, int month) => _monthLength(year, month);

  /// Arabic-Indic numerals, matching the web app's day-cell display.
  static String toArabicIndicNumerals(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => digits[int.parse(c)]).join();
  }
}
