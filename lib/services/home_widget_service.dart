import 'package:home_widget/home_widget.dart';
import '../models/today_data.dart';

class HomeWidgetService {
  static const String iOSAppGroup = 'group.com.yourcompany.interfaithcalendar';

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(iOSAppGroup);
    } catch (_) {
      // Android does not need the iOS app-group call.
    }
  }

  static Future<void> pushToWidget(TodayData data) async {
    try {
      final native = data.native;
      final eventTitle = data.events.isEmpty ? '' : data.events.first.title;

      await HomeWidget.saveWidgetData<String>(
        'native_label',
        native == null
            ? ''
            : '${native.day} ${native.monthName} ${native.year}',
      );
      await HomeWidget.saveWidgetData<String>('fajr', data.prayer.fajr);
      await HomeWidget.saveWidgetData<String>('asr', data.prayer.asr);
      await HomeWidget.saveWidgetData<String>('maghrib', data.prayer.maghrib);
      await HomeWidget.saveWidgetData<String>('isha', data.prayer.isha);
      await HomeWidget.saveWidgetData<String>('event_title', eventTitle);
      await HomeWidget.saveWidgetData<String>(
        'event_count',
        '${data.events.length}',
      );

      await HomeWidget.updateWidget(
        androidName: 'TodayWidgetProvider',
        iOSName: 'TodayWidget',
      );
    } catch (_) {
      // The app remains usable when widget platform setup has not been added yet.
    }
  }
}
