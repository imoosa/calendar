// lib/screens/settings_screen.dart
//
// Samaa calendar settings.
// Mirrors the calendar choices in the web application's settings.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Map<String, String> calendars = {
    'hijri': 'Bohra (Fatimid) Hijri',
    'sunni': 'Sunni (Umm al-Qura) Hijri',
    'shia': 'Shia (Jafari) Hijri',
    'gregorian': 'Gregorian',
    'hebrew': 'Hebrew',
    'parsi': 'Parsi (Shahenshahi)',
    'hindu': 'Hindu (Lunar)',
  };

  static const Map<String, String> secondaryCalendars = {
    '': 'None',
    ...calendars,
  };

  String _defaultCalendar = 'hijri';
  String _secondaryCalendar = 'gregorian';

  bool _bohra = true;
  bool _sunni = true;
  bool _shia = true;
  bool _christian = true;
  bool _jewish = true;
  bool _hindu = true;
  bool _parsi = true;
  bool _french = true;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      final defaultValue =
          prefs.getString('default_calendar') ?? 'hijri';
      final secondaryValue =
          prefs.getString('secondary_calendar') ?? 'gregorian';

      _defaultCalendar = calendars.containsKey(defaultValue)
          ? defaultValue
          : 'hijri';

      _secondaryCalendar =
          secondaryCalendars.containsKey(secondaryValue)
              ? secondaryValue
              : 'gregorian';

      _bohra = prefs.getBool('show_bohra') ?? true;
      _sunni = prefs.getBool('show_sunni') ?? true;
      _shia = prefs.getBool('show_shia') ?? true;
      _christian = prefs.getBool('show_christian') ?? true;
      _jewish = prefs.getBool('show_jewish') ?? true;
      _hindu = prefs.getBool('show_hindu') ?? true;
      _parsi = prefs.getBool('show_parsi') ?? true;
      _french = prefs.getBool('show_french') ?? true;

      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'default_calendar',
      _defaultCalendar,
    );

    await prefs.setString(
      'secondary_calendar',
      _secondaryCalendar,
    );

    await prefs.setBool('show_bohra', _bohra);
    await prefs.setBool('show_sunni', _sunni);
    await prefs.setBool('show_shia', _shia);
    await prefs.setBool('show_christian', _christian);
    await prefs.setBool('show_jewish', _jewish);
    await prefs.setBool('show_hindu', _hindu);
    await prefs.setBool('show_parsi', _parsi);
    await prefs.setBool('show_french', _french);

    if (!mounted) return;

    setState(() => _saving = false);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            'Calendars',
            [
              _dropdown(
                'Default calendar',
                _defaultCalendar,
                calendars,
                (value) {
                  if (value != null) {
                    setState(() {
                      _defaultCalendar = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Secondary calendar',
                _secondaryCalendar,
                secondaryCalendars,
                (value) {
                  if (value != null) {
                    setState(() {
                      _secondaryCalendar = value;
                    });
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          _section(
            'Event visibility',
            [
              _switch(
                'Bohra',
                _bohra,
                (value) {
                  setState(() => _bohra = value);
                },
              ),
              _switch(
                'Sunni',
                _sunni,
                (value) {
                  setState(() => _sunni = value);
                },
              ),
              _switch(
                'Shia',
                _shia,
                (value) {
                  setState(() => _shia = value);
                },
              ),
              _switch(
                'Christian',
                _christian,
                (value) {
                  setState(() => _christian = value);
                },
              ),
              _switch(
                'Jewish',
                _jewish,
                (value) {
                  setState(() => _jewish = value);
                },
              ),
              _switch(
                'Hindu',
                _hindu,
                (value) {
                  setState(() => _hindu = value);
                },
              ),
              _switch(
                'Parsi',
                _parsi,
                (value) {
                  setState(() => _parsi = value);
                },
              ),
              _switch(
                'French',
                _french,
                (value) {
                  setState(() => _french = value);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    final safeValue =
        items.containsKey(value) ? value : items.keys.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          isExpanded: true,
          items: items.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _switch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}
