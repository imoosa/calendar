// lib/screens/settings_screen.dart
//
// Samaa calendar settings.
// Calendar choices mirror the Flask application's CALENDARS registry:
// Bohra, Sunni, Shia, Gregorian, Hebrew, Parsi and Hindu.

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
      _defaultCalendar =
          calendars.containsKey(prefs.getString('default_calendar'))
              ? prefs.getString('default_calendar')!
              : 'hijri';

      final secondary = prefs.getString('secondary_calendar') ?? 'gregorian';
      _secondaryCalendar =
          secondaryCalendars.containsKey(secondary) ? secondary : 'gregorian';

      _loading = false;
    });
  }

  Future<void> _save({
    String? defaultCalendar,
    String? secondaryCalendar,
  }) async {
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();

    if (defaultCalendar != null) {
      await prefs.setString('default_calendar', defaultCalendar);
      _defaultCalendar = defaultCalendar;
    }

    if (secondaryCalendar != null) {
      await prefs.setString('secondary_calendar', secondaryCalendar);
      _secondaryCalendar = secondaryCalendar;
    }

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calendar settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Calendar'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dropdown(
                  label: 'Default calendar',
                  value: _defaultCalendar,
                  items: calendars,
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            _save(defaultCalendar: value);
                          }
                        },
                ),
                const SizedBox(height: 18),
                _dropdown(
                  label: 'Secondary calendar',
                  value: _secondaryCalendar,
                  items: secondaryCalendars,
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            _save(secondaryCalendar: value);
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The Calendar screen uses these selections to show '
                    'the primary date and optional secondary date.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String?>? onChanged,
  ) {
    final safeValue = items.containsKey(value)
        ? value
        : items.keys.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: safeValue,
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
}
