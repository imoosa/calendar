// lib/screens/settings_screen.dart
// Flutter settings corresponding to the calendar choices in web settings.html.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _defaultCalendar = 'hijri';
  String _secondaryCalendar = 'gregorian';
  bool _bohra = true, _sunni = true, _shia = true, _christian = true, _jewish = true, _hindu = true, _parsi = true, _french = true;

  static const calendars = <String, String>{
    'hijri': 'Bohra (Fatimid) Hijri',
    'sunni': 'Sunni (Umm al-Qura) Hijri',
    'shia': 'Shia (Jafari) Hijri',
    'gregorian': 'Gregorian',
    'hebrew': 'Hebrew',
    'parsi': 'Parsi (Shahenshahi)',
    'hindu': 'Hindu (Lunar)',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _defaultCalendar = p.getString('default_calendar') ?? 'hijri';
      _secondaryCalendar = p.getString('secondary_calendar') ?? 'gregorian';
      _bohra = p.getBool('show_bohra') ?? true;
      _sunni = p.getBool('show_sunni') ?? true;
      _shia = p.getBool('show_shia') ?? true;
      _christian = p.getBool('show_christian') ?? true;
      _jewish = p.getBool('show_jewish') ?? true;
      _hindu = p.getBool('show_hindu') ?? true;
      _parsi = p.getBool('show_parsi') ?? true;
      _french = p.getBool('show_french') ?? true;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('default_calendar', _defaultCalendar);
    await p.setString('secondary_calendar', _secondaryCalendar);
    await p.setBool('show_bohra', _bohra); await p.setBool('show_sunni', _sunni); await p.setBool('show_shia', _shia);
    await p.setBool('show_christian', _christian); await p.setBool('show_jewish', _jewish); await p.setBool('show_hindu', _hindu); await p.setBool('show_parsi', _parsi); await p.setBool('show_french', _french);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          _section('Calendars', [
            _dropdown('Default calendar', _defaultCalendar, calendars, (v) => setState(() => _defaultCalendar = v!)),
            const SizedBox(height: 12),
            _dropdown('Secondary calendar', _secondaryCalendar, {'': 'None', ...calendars}, (v) => setState(() => _secondaryCalendar = v!)),
          ]),
          const SizedBox(height: 14),
          _section('Event visibility', [
            _switch('Bohra', _bohra, (v) => setState(() => _bohra = v)),
            _switch('Sunni', _sunni, (v) => setState(() => _sunni = v)),
            _switch('Shia', _shia, (v) => setState(() => _shia = v)),
            _switch('Christian', _christian, (v) => setState(() => _christian = v)),
            _switch('Jewish', _jewish, (v) => setState(() => _jewish = v)),
            _switch('Hindu', _hindu, (v) => setState(() => _hindu = v)),
            _switch('Parsi', _parsi, (v) => setState(() => _parsi = v)),
            _switch('French', _french, (v) => setState(() => _french = v)),
          ]),
          const SizedBox(height: 18),
          SizedBox(height: 48, child: FilledButton(onPressed: _save, child: const Text('Save settings'))),
        ]),
      );

  Widget _section(String title, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 14), ...children])));

  Widget _dropdown(String label, String value, Map<String, String> items, ValueChanged<String?> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)), const SizedBox(height: 5), DropdownButtonFormField<String>(initialValue: items.containsKey(value) ? value : items.keys.first, items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)]);

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) => SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(label), value: value, onChanged: onChanged);
}
