// DEPRECATED: retained for reference only. No offline screen imports this file.
// lib/services/api_service.dart
// Updated for the multi-calendar Flutter Calendar screen.

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
    return Uri.parse('$_baseUrl$path').replace(queryParameters: qp);
  }

  Future<TodayData> fetchToday() async {
    final res = await http.get(_uri('/api/widget/today')).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Server returned ${res.statusCode}: ${res.body}');
    }
    return TodayData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> fetchCalendar({
    required String calendar,
    String secondary = '',
    int? year,
    int? month,
    DateTime? selected,
    List<String>? show,
  }) async {
    final qp = <String, String>{
      'cal': calendar,
      if (secondary.isNotEmpty) 'secondary': secondary,
      if (year != null) 'y': '$year',
      if (month != null) 'm': '$month',
      if (selected != null) 'selected': _iso(selected),
    };

    var uri = _uri('/api/mobile/calendar', qp);
    if (show != null && show.isNotEmpty) {
      final parts = <String>[];
      qp.forEach((k, v) => parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}'));
      for (final value in show) {
        parts.add('show=${Uri.encodeQueryComponent(value)}');
      }
      uri = Uri.parse('$_baseUrl/api/mobile/calendar?${parts.join('&')}');
    }

    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Server returned ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchVastuToday() async {
    final res = await http.get(_uri('/api/vastu/today')).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('Server returned ${res.statusCode}: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchQibla(double lat, double lng) async {
    final res = await http.get(_uri('/api/qibla', {'lat': '$lat', 'lng': '$lng'})).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('Server returned ${res.statusCode}: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchGeneralEvents({
    required DateTime start,
    required DateTime end,
    double? lat,
    double? lng,
    double? tzOffset,
    List<String>? show,
  }) async {
    final parts = <String>[
      'start=${Uri.encodeQueryComponent(_iso(start))}',
      'end=${Uri.encodeQueryComponent(_iso(end))}',
      if (lat != null) 'lat=${Uri.encodeQueryComponent('$lat')}',
      if (lng != null) 'lng=${Uri.encodeQueryComponent('$lng')}',
      if (tzOffset != null) 'tz_offset=${Uri.encodeQueryComponent('$tzOffset')}',
    ];
    if (show != null) {
      for (final value in show) {
        parts.add('show=${Uri.encodeQueryComponent(value)}');
      }
    }

    final uri = Uri.parse('$_baseUrl/api/mobile/events?${parts.join('&')}');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw Exception('Server returned ${res.statusCode}: ${res.body}');
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
