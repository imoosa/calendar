# Interfaith Calendar — Flutter app + native widgets

## What's here
- `pubspec.yaml`, `lib/` — the Flutter app (Today, Calendar, Qibla, Vastu, Events).
  Shared Dart code, runs on both Android and iOS.
- `android_widget/` — Kotlin/Glance home-screen widget + setup steps.
- `ios_widget/` — Swift/WidgetKit home-screen widget + setup steps.

## What you need to actually build this (not included here, requires your machine)
1. Install the Flutter SDK: https://docs.flutter.dev/get-started/install
2. `flutter create .` in this folder the first time, to generate the
   `android/` and `ios/` native project folders (this scaffold only has the
   Dart source + native widget files, not the full generated Xcode/Gradle
   projects — those are machine- and signing-account-specific).
3. `flutter pub get`
4. Follow `android_widget/README_ANDROID_SETUP.md` and
   `ios_widget/README_IOS_SETUP.md` to wire in the native widget targets.
5. Set your real backend URL when building:
   `flutter run --dart-define=API_BASE_URL=https://your-real-domain.com`

## Backend contract this app expects from your existing Flask app
- `GET /api/widget/today` — already exists per widget_today.html; reused as-is.
- `GET /api/calendar/month?year=&month=` — new, for the Calendar screen. Needs
  to return a list of `{day, native_label, events: [{title, color}]}`.
- `GET /api/vastu/today` — new, for the Vastu screen. Shape is a placeholder
  in `vastu_screen.dart`; adjust the keys to whatever you decide to return.

## Honest gaps in this scaffold
- Not compiled/tested — I don't have a Flutter toolchain in this environment.
  Expect minor package-version fixes on first `flutter pub get`.
- Qibla screen needs real device permissions setup
  (`NSLocationWhenInUseUsageDescription` in iOS Info.plist,
  `ACCESS_FINE_LOCATION` in AndroidManifest.xml) — not included, add during
  `flutter create` native project setup.
- No offline caching of Today data yet beyond what the widget itself stores —
  add `shared_preferences` read/write in `today_screen.dart` if you want the
  app screen to show last-known data with no network.
- No auth — add if these routes carry any private/personal data (e.g.
  personal events).
