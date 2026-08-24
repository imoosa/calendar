// lib/services/home_widget_service.dart
//
// Writes the keys TodayWidgetProvider.kt (Android) and TodayWidget.swift
// (iOS) both read: native_label, fajr, asr, maghrib, isha, event_title,
// event_count. Keep these key names in sync across all three files if
// you ever rename one.

import 'package:home_widget/home_widget.dart';
import '../models/today_data.dart';

class HomeWidgetService {
  // Must match appGroupId in TodayWidget.swift exactly.
  static const _iosAppGroupId = 'group.com.yourcompany.interfaithcalendar';
  // Must match the `kind` string in TodayWidget.swift, and the Android
  // provider class name TodayWidgetProvider.kt declares.
  static const _iosWidgetKind = 'TodayWidget';
  static const _androidProviderName = 'TodayWidgetProvider';

  static Future<void> init() async {
    // No-op on Android; required on iOS so home_widget knows which
    // App Group's shared UserDefaults to write into.
    await HomeWidget.setAppGroupId(_iosAppGroupId);
  }

  static Future<void> pushToWidget(TodayData data) async {
    final nativeLabel = data.native != null
        ? '${data.native!.day} ${data.native!.monthName} ${data.native!.year}'
        : '';
    final firstEvent = data.events.isNotEmpty ? data.events.first.title : '';

    await HomeWidget.saveWidgetData<String>('native_label', nativeLabel);
    await HomeWidget.saveWidgetData<String>('fajr', data.prayer.fajr);
    await HomeWidget.saveWidgetData<String>('asr', data.prayer.asr);
    await HomeWidget.saveWidgetData<String>('maghrib', data.prayer.maghrib);
    await HomeWidget.saveWidgetData<String>('isha', data.prayer.isha);
    await HomeWidget.saveWidgetData<String>('event_title', firstEvent);
    await HomeWidget.saveWidgetData<String>('event_count', data.events.length.toString());

    await HomeWidget.updateWidget(
      androidName: _androidProviderName,
      iOSName: _iosWidgetKind,
    );
  }
}
