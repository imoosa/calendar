// lib/models/today_data.dart
//
// Mirrors the JSON shape of GET /api/widget/today exactly (see
// _today_widget_data() / api_widget_today() in main.py). If you change
// that endpoint's response keys, update fromJson here to match.

class NativeDate {
  final String calendarLabel;
  final String monthName;
  final String day; // server sends int for most calendars, Arabic-Indic
  // string for Islamic ones (hc.to_arabic_indic_numerals) -- kept as
  // String here so both cases render without a type crash.
  final int year;

  NativeDate({
    required this.calendarLabel,
    required this.monthName,
    required this.day,
    required this.year,
  });

  factory NativeDate.fromJson(Map<String, dynamic> json) {
    return NativeDate(
      calendarLabel: json['calendar_label']?.toString() ?? '',
      monthName: json['month_name']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      year: json['year'] is int ? json['year'] as int : int.tryParse('${json['year']}') ?? 0,
    );
  }
}

class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String zawal;
  final String asr;
  final String zuhrEnd;
  final String sunset;
  final String maghrib;
  final String isha;

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.zawal,
    required this.asr,
    required this.zuhrEnd,
    required this.sunset,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    String s(String key) => json[key]?.toString() ?? '--:--';
    return PrayerTimes(
      fajr: s('fajr'),
      sunrise: s('sunrise'),
      zawal: s('zawal'),
      asr: s('asr'),
      zuhrEnd: s('zuhr_end'),
      sunset: s('sunset'),
      maghrib: s('maghrib'),
      isha: s('isha'),
    );
  }
}

class EventItem {
  final String title;
  final String? description;
  final bool isHoliday;
  final bool isFastingDay;
  final String? color;
  final String? tradition; // only present on interfaith events

  EventItem({
    required this.title,
    this.description,
    this.isHoliday = false,
    this.isFastingDay = false,
    this.color,
    this.tradition,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      isHoliday: json['is_holiday'] == true,
      isFastingDay: json['is_fasting_day'] == true,
      color: json['color']?.toString(),
      tradition: json['tradition']?.toString(),
    );
  }
}

class TodayData {
  final String date;
  final NativeDate? native;
  final List<EventItem> events;
  final PrayerTimes prayer;
  final String locationName;

  TodayData({
    required this.date,
    required this.native,
    required this.events,
    required this.prayer,
    required this.locationName,
  });

  factory TodayData.fromJson(Map<String, dynamic> json) {
    return TodayData(
      date: json['date']?.toString() ?? '',
      native: json['native'] != null
          ? NativeDate.fromJson(json['native'] as Map<String, dynamic>)
          : null,
      events: (json['events'] as List<dynamic>? ?? [])
          .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      prayer: PrayerTimes.fromJson(
          (json['prayer_times'] as Map<String, dynamic>?) ?? const {}),
      locationName: json['location_name']?.toString() ?? '',
    );
  }
}
