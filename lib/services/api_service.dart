import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/today_data.dart';

class ApiConfig {
  // Production Flask server.
  // Override at build time with:
  // flutter build apk --dart-define=API_BASE_URL=https://example.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://calendar.mactronik.com',
  );

  static const Duration timeout = Duration(seconds: 20);
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String _cacheKey = 'cached_events_response';
  static const String _cacheDateKey = 'cached_events_synced_at';

  Uri _uri(
    String path, [
    Map<String, dynamic>? query,
  ]) {
    final params = <String, String>{};

    query?.forEach((key, value) {
      if (value != null) {
        params[key] = value.toString();
      }
    });

    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Future<dynamic> _get(Uri uri) async {
    final response = await http
        .get(uri)
        .timeout(ApiConfig.timeout);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw ApiException(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Server returned invalid JSON.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TODAY
  // ─────────────────────────────────────────────────────────────

  /// GET /api/widget/today
  ///
  /// Returns:
  /// - Gregorian date
  /// - Native calendar information
  /// - Prayer times
  /// - Today's events
  /// - Location
  Future<TodayData> fetchToday() async {
    final data = await _get(
      _uri('/api/widget/today'),
    );

    if (data is! Map) {
      throw ApiException(
        'Invalid Today response from server.',
      );
    }

    return TodayData.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HIJRI CALENDAR
  // ─────────────────────────────────────────────────────────────

  /// GET /api/calendar/today
  Future<Map<String, dynamic>> fetchHijriToday() async {
    final data = await _get(
      _uri('/api/calendar/today'),
    );

    if (data is! Map) {
      throw ApiException(
        'Invalid calendar/today response.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  /// GET /api/calendar/month/<hijri_year>/<hijri_month>
  Future<Map<String, dynamic>> fetchHijriMonth(
    int year,
    int month,
  ) async {
    final data = await _get(
      _uri('/api/calendar/month/$year/$month'),
    );

    if (data is! Map) {
      throw ApiException(
        'Invalid calendar/month response.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // ─────────────────────────────────────────────────────────────
  // GENERAL EVENTS
  // ─────────────────────────────────────────────────────────────

  /// GET /api/mobile/events
  ///
  /// The Flask backend uses request.args.getlist("show").
  /// Therefore multiple communities are sent as:
  ///
  /// ?show=bohra&show=sunni&show=shia
  ///
  /// rather than:
  ///
  /// ?show=bohra,sunni,shia
  ///
  /// PersonalEvent records are intentionally not requested from
  /// this public mobile endpoint.
  Future<Map<String, dynamic>> fetchGeneralEvents({
    required DateTime start,
    required DateTime end,
    double? lat,
    double? lng,
    double? tzOffset,
    List<String>? show,
  }) async {
    final queryParts = <String>[
      'start=${Uri.encodeQueryComponent(_isoDate(start))}',
      'end=${Uri.encodeQueryComponent(_isoDate(end))}',
    ];

    if (lat != null) {
      queryParts.add(
        'lat=${Uri.encodeQueryComponent(lat.toString())}',
      );
    }

    if (lng != null) {
      queryParts.add(
        'lng=${Uri.encodeQueryComponent(lng.toString())}',
      );
    }

    if (tzOffset != null) {
      queryParts.add(
        'tz_offset=${Uri.encodeQueryComponent(tzOffset.toString())}',
      );
    }

    if (show != null) {
      for (final tradition in show) {
        if (tradition.trim().isEmpty) {
          continue;
        }

        queryParts.add(
          'show=${Uri.encodeQueryComponent(tradition.trim())}',
        );
      }
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/mobile/events'
      '?${queryParts.join('&')}',
    );

    try {
      final response = await http
          .get(uri)
          .timeout(ApiConfig.timeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw ApiException(
          'Server returned ${response.statusCode}: '
          '${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw ApiException(
          'Invalid events response from server.',
        );
      }

      final data = Map<String, dynamic>.from(decoded);

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

  // ─────────────────────────────────────────────────────────────
  // PRAYER TIMES
  // ─────────────────────────────────────────────────────────────

  /// GET /api/prayer-times
  Future<Map<String, dynamic>> fetchPrayerTimes({
    required double lat,
    required double lng,
    required double tzOffset,
    DateTime? date,
  }) async {
    final data = await _get(
      _uri(
        '/api/prayer-times',
        {
          'lat': lat,
          'lng': lng,
          'tz_offset': tzOffset,
          if (date != null)
            'for_date': _isoDate(date),
        },
      ),
    );

    if (data is! Map) {
      throw ApiException(
        'Invalid prayer-times response.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // ─────────────────────────────────────────────────────────────
  // TIMEZONE
  // ─────────────────────────────────────────────────────────────

  /// GET /api/tz-offset
  Future<Map<String, dynamic>> fetchTimezone({
    required double lat,
    required double lng,
    DateTime? date,
  }) async {
    final data = await _get(
      _uri(
        '/api/tz-offset',
        {
          'lat': lat,
          'lng': lng,
          if (date != null)
            'for_date': _isoDate(date),
        },
      ),
    );

    if (data is! Map) {
      throw ApiException(
        'Invalid timezone response.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // ─────────────────────────────────────────────────────────────
  // QIBLA
  // ─────────────────────────────────────────────────────────────

  /// GET /api/qibla?lat=&lng=
  Future<Map<String, dynamic>> fetchQibla({
    required double lat,
    required double lng,
  }) async {
    final data = await _get(
      _uri(
        '/api/qibla',
        {
          'lat': lat,
          'lng': lng,
        },
      ),
    );

    if (data is! Map) {
      throw ApiException(
        'Invalid Qibla response.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // ─────────────────────────────────────────────────────────────
  // VASTU
  // ─────────────────────────────────────────────────────────────

  /// GET /api/vastu/today
  Future<Map<String, dynamic>> fetchVastuToday() async {
    final data = await _get(
      _uri('/api/vastu/today'),
    );

    if (data is! Map) {
      throw ApiException(
        'Invalid Vastu response.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // ─────────────────────────────────────────────────────────────
  // CACHE
  // ─────────────────────────────────────────────────────────────

  Future<void> _saveToCache(
    Map<String, dynamic> data,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _cacheKey,
      jsonEncode(data),
    );

    await prefs.setString(
      _cacheDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, dynamic>?> _loadFromCache() async {
    final prefs =
        await SharedPreferences.getInstance();

    final raw = prefs.getString(_cacheKey);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DATE HELPERS
  // ─────────────────────────────────────────────────────────────

  String _isoDate(DateTime value) {
    final d = DateTime(
      value.year,
      value.month,
      value.day,
    );

    return d.toIso8601String().substring(0, 10);
  }
}
