class NativeCalendarData {
  final String calendarLabel;
  final String monthName;
  final dynamic day;
  final int year;

  NativeCalendarData({
    required this.calendarLabel,
    required this.monthName,
    required this.day,
    required this.year,
  });

  factory NativeCalendarData.fromJson(Map<String, dynamic> json) {
    return NativeCalendarData(
      calendarLabel: '${json['calendar_label'] ?? 'Calendar'}',
      monthName: '${json['month_name'] ?? ''}',
      day: json['day'] ?? '',
      year: int.tryParse('${json['year'] ?? 0}') ?? 0,
    );
  }
}

class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String zuhrEnd;
  final String sunset;
  final String maghrib;
  final String isha;
  final String zawal;

  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.zuhrEnd,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.zawal,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    String v(String key, [String fallback = '--:--']) =>
        '${json[key] ?? fallback}';

    final dhuhr = v('dhuhr', v('zuhr', v('zawal')));

    return PrayerTimes(
      fajr: v('fajr'),
      sunrise: v('sunrise'),
      dhuhr: dhuhr,
      asr: v('asr'),
      zuhrEnd: v('zuhr_end', v('zuhrEnd', v('asr'))),
      sunset: v('sunset'),
      maghrib: v('maghrib', v('sunset')),
      isha: v('isha'),
      zawal: v('zawal', dhuhr),
    );
  }
}

class EventItem {
  final String title;
  final String? description;
  final String? color;
  final String? source;
  final bool isHoliday;
  final bool isFasting;

  EventItem({
    required this.title,
    this.description,
    this.color,
    this.source,
    this.isHoliday = false,
    this.isFasting = false,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      title: '${json['title'] ?? ''}',
      description: json['description']?.toString(),
      color: json['color']?.toString(),
      source: json['event_source']?.toString() ?? json['source']?.toString(),
      isHoliday: json['is_holiday'] == true,
      isFasting: json['is_fasting_day'] == true,
    );
  }
}

class TodayData {
  final String date;
  final NativeCalendarData? native;
  final PrayerTimes prayer;
  final List<EventItem> events;
  final List<EventItem> hijriEvents;
  final List<EventItem> interfaithEvents;
  final List<EventItem> personalEvents;
  final String locationName;

  TodayData({
    required this.date,
    required this.native,
    required this.prayer,
    required this.events,
    required this.hijriEvents,
    required this.interfaithEvents,
    required this.personalEvents,
    required this.locationName,
  });

  factory TodayData.fromJson(Map<String, dynamic> json) {
    List<EventItem> list(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => EventItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final hijri = list(json['hijri_events']);
    final interfaith = list(json['interfaith_events']);
    final personal = list(json['personal_events']);

    return TodayData(
      date: '${json['date'] ?? ''}',
      native: json['native'] is Map
          ? NativeCalendarData.fromJson(
              Map<String, dynamic>.from(json['native']),
            )
          : null,
      prayer: PrayerTimes.fromJson(
        Map<String, dynamic>.from(
          (json['prayer_times'] ?? json['prayer'] ?? {}) as Map,
        ),
      ),
      events: list(json['events']).isNotEmpty
          ? list(json['events'])
          : [...hijri, ...interfaith, ...personal],
      hijriEvents: hijri,
      interfaithEvents: interfaith,
      personalEvents: personal,
      locationName: '${json['location_name'] ?? 'Unknown location'}',
    );
  }
}
