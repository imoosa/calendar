import 'package:flutter/material.dart';
import 'services/home_widget_service.dart';
import 'screens/today_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/vastu_screen.dart';
import 'screens/events_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidgetService.init();
  runApp(const InterfaithCalendarApp());
}

class InterfaithCalendarApp extends StatelessWidget {
  const InterfaithCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFFB5121B);
    return MaterialApp(
      title: 'Interfaith Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: maroon,
        appBarTheme: const AppBarTheme(
          backgroundColor: maroon,
          foregroundColor: Colors.white,
        ),
      ),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    TodayScreen(),
    CalendarScreen(),
    QiblaScreen(),
    VastuScreen(),
    EventsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Qibla'),
          NavigationDestination(icon: Icon(Icons.home_work), label: 'Vastu'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
        ],
      ),
    );
  }
}
