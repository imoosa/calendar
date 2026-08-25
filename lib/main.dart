import 'package:flutter/material.dart';
import 'services/home_widget_service.dart';
import 'screens/today_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/vastu_screen.dart';
import 'screens/events_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidgetService.init();
  runApp(const InterfaithCalendarApp());
}

class InterfaithCalendarApp extends StatelessWidget {
  const InterfaithCalendarApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Samaa',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const RootShell(),
      );
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [const TodayScreen(), const CalendarScreen(), const QiblaScreen(), const VastuScreen(), const EventsScreen(), const SettingsScreen()];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() {
            _index = i;
            if (i == 1) {
              _screens[1] = CalendarScreen(key: UniqueKey());
            }
          }),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Qibla'),
            NavigationDestination(icon: Icon(Icons.home_work_outlined), selectedIcon: Icon(Icons.home_work), label: 'Vastu'),
            NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      );
}
