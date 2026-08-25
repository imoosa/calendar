// Dart port of prayer_times_accurate.py -- same solar-position formulas,
// same angles (Fajr/Isha 18 deg, sunset 0.833 deg), same Shafi'i Asr.

import 'dart:math' as math;

const double kFajrAngle = 18.0;
const double kIshaAngle = 18.0;
const double kSunsetAngle = 0.833;

class PrayerTimes {
  final String fajr, sunrise, zawal, asr, zuhrEnd, sunset, maghrib, isha;
  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.zawal,
    required this.asr,
    required this.zuhrEnd,
    required this.sunset,
    required this.maghrib,
    required this.isha,
  });
}

double _julianDay(DateTime d) {
  final a = (14 - d.month) ~/ 12;
  final y = d.year + 4800 - a;
  final m = d.month + 12 * a - 3;
  return (d.day +
          ((153 * m + 2) ~/ 5) +
          365 * y +
          (y ~/ 4) -
          (y ~/ 100) +
          (y ~/ 400) -
          32045)
      .toDouble();
}

(double, double) _sunPosition(double jd) {
  final D = jd - 2451545.0;
  final g = _rad((357.529 + 0.98560028 * D) % 360);
  final q = (280.459 + 0.98564736 * D) % 360;
  final L = _rad((q + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g)) % 360);
  final e = _rad(23.439 - 0.00000036 * D);
  final dec = math.asin(math.sin(e) * math.sin(L));
  var ra = _deg(math.atan2(math.cos(e) * math.sin(L), math.cos(L))) / 15.0;
  ra = ra % 24;
  if (ra < 0) ra += 24;
  var eqt = q / 15.0 - ra;
  if (eqt > 12) eqt -= 24;
  if (eqt < -12) eqt += 24;
  return (_deg(dec), eqt);
}

double _rad(double d) => d * math.pi / 180.0;
double _deg(double r) => r * 180.0 / math.pi;

double _timeForAngle(double jd, double lat, double lng, double angle,
    bool beforeNoon, double noonUtc) {
  final (dec, _) = _sunPosition(jd);
  final latR = _rad(lat);
  final decR = _rad(dec);
  double h;
  try {
    var cosH = (math.sin(_rad(-angle)) - math.sin(latR) * math.sin(decR)) /
        (math.cos(latR) * math.cos(decR));
    cosH = cosH.clamp(-1.0, 1.0);
    h = _deg(math.acos(cosH)) / 15.0;
  } catch (_) {
    h = 6.0;
  }
  return beforeNoon ? noonUtc - h : noonUtc + h;
}

double _asrTime(double jd, double lat, double lng, {double shadowFactor = 1.0}) {
  final (dec, eqt) = _sunPosition(jd);
  final latR = _rad(lat);
  final decR = _rad(dec);
  final noonUtc = 12.0 - lng / 15.0 - eqt;
  final altitude = math.atan(1.0 / shadowFactor);
  var cosH = (math.sin(altitude) - math.sin(latR) * math.sin(decR)) /
      (math.cos(latR) * math.cos(decR));
  cosH = cosH.clamp(-1.0, 1.0);
  final h = _deg(math.acos(cosH)) / 15.0;
  return noonUtc + h;
}

String _toLocal(double utcHours, double tzOffset) {
  var h = (utcHours + tzOffset) % 24;
  if (h < 0) h += 24;
  var hh = h.floor();
  var mm = ((h - hh) * 60).round();
  if (mm == 60) {
    mm = 0;
    hh = (hh + 1) % 24;
  }
  return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
}

PrayerTimes calculatePrayerTimes(double lat, double lng, DateTime d, double tzOffsetHours) {
  final jd = _julianDay(d);
  final (_, eqt) = _sunPosition(jd);
  final noonUtc = 12.0 - lng / 15.0 - eqt;

  final sunriseUtc = _timeForAngle(jd, lat, lng, kSunsetAngle, true, noonUtc);
  final sunsetUtc = _timeForAngle(jd, lat, lng, kSunsetAngle, false, noonUtc);
  final fajrUtc = _timeForAngle(jd, lat, lng, kFajrAngle, true, noonUtc);
  final ishaUtc = _timeForAngle(jd, lat, lng, kIshaAngle, false, noonUtc);
  final asrUtc = _asrTime(jd, lat, lng, shadowFactor: 1.0);

  return PrayerTimes(
    fajr: _toLocal(fajrUtc, tzOffsetHours),
    sunrise: _toLocal(sunriseUtc, tzOffsetHours),
    zawal: _toLocal(noonUtc, tzOffsetHours),
    asr: _toLocal(asrUtc, tzOffsetHours),
    zuhrEnd: _toLocal(asrUtc, tzOffsetHours),
    sunset: _toLocal(sunsetUtc, tzOffsetHours),
    maghrib: _toLocal(sunsetUtc, tzOffsetHours),
    isha: _toLocal(ishaUtc, tzOffsetHours),
  );
}
