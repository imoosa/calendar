import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/today_data.dart';

class ApiConfig {
  // Change only this line if your Flask server is hosted elsewhere.
  static const String baseUrl = 'https://calendar.mactronik.com';
  static const Duration timeout = Duration(seconds: 20);
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null) params[key] = '$value';
    });
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: params);
  }

  Future<dynamic> _get(Uri uri) async {
    final response = await http.get(uri).timeout(ApiConfig.timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Server returned ${response.statusCode}: ${response.body}');
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Server returned invalid JSON.');
    }
  }

  Future<TodayData> fetchToday() async {
    final data = await _get(_uri('/api/widget/today'));
    return TodayData.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> fetchHijriToday() async {
    final data = await _get(_uri('/api/calendar/today'));
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> fetchHijriMonth(int year, int month) async {
    final data = await _get(
      _uri('/api/calendar/month/$year/$month'),
    );
    return Map<String, dynamic>.from(data);
  }

Future<Map<String, dynamic>> fetchGeneralEvents({
  required DateTime start,
  required DateTime end,
  double? lat,
  double? lng,
  double? tzOffset,
  List<String>? show,
}) async {
  final params = <String>[
    'start=${Uri.encodeQueryComponent(_iso(start))}',
    'end=${Uri.encodeQueryComponent(_iso(end))}',
    if (lat != null) 'lat=${Uri.encodeQueryComponent(lat.toString())}',
    if (lng != null) 'lng=${Uri.encodeQueryComponent(lng.toString())}',
    if (tzOffset != null)
      'tz_offset=${Uri.encodeQueryComponent(tzOffset.toString())}',
  ];

  // Flask uses request.args.getlist("show"), so each community
  // must be sent as a separate ?show=value parameter.
  if (show != null) {
    for (final value in show) {
      params.add('show=${Uri.encodeQueryComponent(value)}');
    }
  }

  final uri = Uri.parse(
    '$_baseUrl/api/mobile/events?${params.join('&')}',
  );

  try {
    final res = await http
        .get(uri)
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    await _saveToCache(data);
    return data;
  } catch (e) {
    final cached = await _loadFromCache();

    if (cached != null) {
      return cached;
    }

    rethrow;
  }
}

  Future<Map<String, dynamic>> fetchPrayerTimes({
    required double lat,
    required double lng,
    required double tzOffset,
    DateTime? date,
  }) async {
    final data = await _get(
      _uri('/api/prayer-times', {
        'lat': lat,
        'lng': lng,
        'tz_offset': tzOffset,
        if (date != null) 'for_date': _isoDate(date),
      }),
    );
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> fetchTimezone({
    required double lat,
    required double lng,
    DateTime? date,
  }) async {
    final data = await _get(
      _uri('/api/tz-offset', {
        'lat': lat,
        'lng': lng,
        if (date != null) 'for_date': _isoDate(date),
      }),
    );
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> fetchQibla({
    required double lat,
    required double lng,
  }) async {
    final data = await _get(
      _uri('/api/qibla', {'lat': lat, 'lng': lng}),
    );
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> fetchVastuToday() async {
    final data = await _get(_uri('/api/vastu/today'));
    return Map<String, dynamic>.from(data);
  }

  String _isoDate(DateTime value) {
    final d = DateTime(value.year, value.month, value.day);
    return d.toIso8601String().substring(0, 10);
  }
}
