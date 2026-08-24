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
    Set<String>? show,
  }) async {
    final query = <String, dynamic>{
      'start': _isoDate(start),
      'end': _isoDate(end),
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (tzOffset != null) 'tz_offset': tzOffset,
    };

    final uri = _uri('/api/mobile/events', query);
    final base = uri.toString();
    final showValues = show ??
        {
          'bohra',
          'sunni',
          'shia',
          'christian',
          'french',
          'jewish',
          'hindu',
          'parsi',
        };

    final withShows = Uri.parse(base).replace(
      queryParametersAll: {
        ...uri.queryParametersAll,
        'show': showValues.toList(),
      },
    );

    final data = await _get(withShows);
    return Map<String, dynamic>.from(data);
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
