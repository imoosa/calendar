Samaa - Offline Flutter architecture

This update removes runtime dependence on the Flask/API server from:
- Today
- Calendar
- Events
- Vastu
- Qibla
- Settings

Calendar and event data are computed locally from the supplied Dart ports/data:
- Bohra/Fatimid Hijri
- Sunni/Umm al-Qura
- Shia (shares Umm al-Qura conversion; separate event table)
- Parsi/Shahenshahi
- Gregorian
- Christian/French/Parsi/Hindu/Jewish interfaith event tables supplied
- local prayer-time calculation

IMPORTANT LIMITATION:
The supplied offline calendar_screen.dart explicitly says Hebrew and Hindu month/date
math are not ported and currently fall back to a Gregorian grid. The supplied
interfaith_events_data.dart says Hindu/Jewish event dates are precomputed only for
2025-2027. Do not treat this package as a complete mathematical port of the web
Hindu/Hebrew engines yet.

The existing API service file is no longer imported by these screens. You may delete
lib/services/api_service.dart after confirming no other project file imports it.

Keep your existing lib/theme.dart and pubspec.yaml. Required packages already used
by the supplied app include:
- shared_preferences
- intl
- home_widget
- flutter_compass
- geolocator

Copy the lib folder contents into the Flutter project, preserving folders.

Then:
flutter clean
flutter pub get
flutter analyze
flutter build apk --debug
