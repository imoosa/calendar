# Samaa Flutter update

This update converts the existing Flutter shell into a Samaa-branded mobile app and connects it directly to the Flask API already present in the Python backend.

## Files included

- `lib/main.dart`
- `lib/theme.dart`
- `lib/models/today_data.dart`
- `lib/services/api_service.dart`
- `lib/services/home_widget_service.dart`
- `lib/screens/today_screen.dart`
- `lib/screens/calendar_screen.dart`
- `lib/screens/events_screen.dart`
- `lib/screens/qibla_screen.dart`
- `lib/screens/vastu_screen.dart`
- `lib/screens/settings_screen.dart`
- `pubspec.yaml`

## Backend routes used

- `/api/widget/today`
- `/api/calendar/today`
- `/api/calendar/month/<hijri_year>/<hijri_month>`
- `/api/mobile/events`
- `/api/prayer-times`
- `/api/tz-offset`
- `/api/qibla`
- `/api/vastu/today`

## Install

Run:

    flutter pub get

Then:

    flutter run

## Important

`lib/services/api_service.dart` contains the backend base URL:

    https://calendar.mactronik.com

Change that one value if the Flask server is hosted at another address.

## Qibla permissions

Android needs location permission in `android/app/src/main/AndroidManifest.xml`:

    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

iOS needs `NSLocationWhenInUseUsageDescription` in `ios/Runner/Info.plist`.

## Home-screen widgets

The Dart widget bridge is included. The existing Android `TodayWidgetProvider.kt` and iOS `TodayWidget.swift` must remain in their platform targets. Their app-group/package identifiers must match the identifiers in the native projects.

## Architecture

The Python backend remains the source of truth for calendar conversion, shared religious/interfaith events, prayer times, Qibla bearing/distance and Vastu. Flutter is the presentation/client layer.
