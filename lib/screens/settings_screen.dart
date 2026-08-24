import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _keys = [
    'bohra',
    'sunni',
    'shia',
    'christian',
    'jewish',
    'hindu',
    'parsi',
    'french',
  ];

  Map<String, bool> _visible = {
    for (final key in _keys) key: true,
  };

  final _api = ApiService();
  String _serverStatus = 'Checking…';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in _keys) {
      _visible[key] = prefs.getBool('show_$key') ?? true;
    }

    try {
      await _api.fetchHijriToday();
      _serverStatus = 'Connected';
    } catch (_) {
      _serverStatus = 'Not connected';
    }

    if (mounted) setState(() {});
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() => _visible[key] = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_$key', value);
  }

  @override
  Widget build(BuildContext context) {
    const labels = {
      'bohra': 'Bohra',
      'sunni': 'Sunni',
      'shia': 'Shia',
      'christian': 'Christian',
      'jewish': 'Jewish',
      'hindu': 'Hindu',
      'parsi': 'Parsi',
      'french': 'French',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          InfoCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.maroon.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.public, color: AppColors.maroon),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Samaa Calendar',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Faith • Time • Harmony',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const ListTile(
                  title: Text(
                    'Communities',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('Choose which traditions appear in the app.'),
                ),
                ...labels.entries.map(
                  (entry) => SwitchListTile(
                    title: Text(entry.value),
                    value: _visible[entry.key] ?? true,
                    activeColor: AppColors.maroon,
                    onChanged: (value) => _toggle(entry.key, value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            child: Row(
              children: [
                const Icon(Icons.cloud_done_outlined, color: AppColors.maroon),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Backend status',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _serverStatus,
                  style: TextStyle(
                    color: _serverStatus == 'Connected'
                        ? AppColors.parsi
                        : AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
