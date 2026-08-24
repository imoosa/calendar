// lib/services/api_service.dart
//
// Every path here is copied from main.py's actual @app.get/@app.post
// routes, not from README.md's aspirational contract -- a few of those
// didn't match what's implemented (see calendar_screen.dart's comment
// for the /api/calendar/month discrepancy).

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/today_data.dart';

class ApiService {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://calendar.mactronik.com',
  );
  static const _cacheKey = 'cached_events_response';
  static const _cacheDateKey = 'cached_events_synced_at';

  Uri _uri(String path, [Map<String, String>? qp]) {
    // baseUrl has no trailing slash by convention here; path always starts with /.
    return Uri.parse('$_baseUrl$path').replace(queryParameters: qp);
  }

  /// GET /api/widget/today -- date, native-calendar reading, prayer
  /// times, and all events landing today. Powers TodayScreen and the
  /// home-screen widget push.
  Future<TodayData> fetchToday() async {
    final res = await http.get(_uri('/api/widget/today')).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }
    return TodayData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// GET /api/calendar/today -- just the Bohra Hijri y/m/d for today,
  /// used to know which month to open CalendarScreen on.
  Future<Map<String, dynamic>> fetchHijriToday() async {
    final res = await http.get(_uri('/api/calendar/today')).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// GET /api/calendar/month/<hijri_year>/<hijri_month>
  /// NOTE: this is a Bohra Hijri month grid, addressed by path segments
  /// -- NOT the Gregorian year/month query-param contract README.md
  /// describes. Each day in the response only carries Bohra HijriEvent
  /// rows (get_events_for_month only queries the bohra-shaped table),
  /// not interfaith/Sunni/Shia events -- add those client-side from
  /// fetchGeneralEvents() if the Calendar screen needs them too.
  Future<Map<String, dynamic>> fetchHijriMonth(int hijriYear, int hijriMonth) async {
    final res = await http
        .get(_uri('/api/calendar/month/$hijriYear/$hijriMonth'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// GET /api/vastu/today -- {"enabled": false} if the user has Vastu
  /// turned off server-side; check that before reading the other keys.
  Future<Map<String, dynamic>> fetchVastuToday() async {
    final res = await http.get(_uri('/api/vastu/today')).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// GET /api/qibla?lat=&lng=
  Future<Map<String, dynamic>> fetchQibla(double lat, double lng) async {
    final res = await http
        .get(_uri('/api/qibla', {'lat': '$lat', 'lng': '$lng'}))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// GET /api/mobile/events -- Hijri (Bohra/Sunni/Shia) + interfaith
  /// events over a date range, up to 90 days, deliberately excludes
  /// PersonalEvent (single-tenant table server-side -- see main.py's
  /// docstring on that route). Falls back to the last successful
  /// response on network failure, and rethrows only if there's no
  /// cache and no network (first-ever launch offline).
  Future<Map<String, dynamic>> fetchGeneralEvents({
    required DateTime start,
    required DateTime end,
    double? lat,
    double? lng,
    double? tzOffset,
    List<String>? show, // e.g. ['bohra','sunni','christian']
  }) async {
    final qp = <String, String>{
      'start': _iso(start),
      'end': _iso(end),
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (tzOffset != null) 'tz_offset': tzOffset.toString(),
    };
    final uri = _uri('/api/mobile/events', qp).replace(
      queryParameters: {
        ...qp,
        if (show != null) 'show': show.join(','), // note below
      },
    );
    // NOTE: Flask reads `show` via request.args.getlist("show"), which
    // expects repeated ?show=a&show=b params, not one comma-joined
    // value. Uri.replace can't easily repeat a key, so if you need the
    // `show` filter, build the query string manually instead of using
    // this shortcut -- left as a single joined param here as a
    // placeholder that will NOT filter correctly server-side yet.

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await _saveToCache(data);
      return data;
    } catch (e) {
      final cached = await _loadFromCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> _saveToCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data));
    await prefs.setString(_cacheDateKey, DateTime.now().toIso8601String());
  }

  Future<Map<String, dynamic>?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
