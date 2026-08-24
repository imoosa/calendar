// This file goes in a separate Widget Extension target inside your Xcode
// project (File > New > Target > Widget Extension, name it "TodayWidget").
// It cannot live inside the main Flutter/Runner target — WidgetKit requires
// its own extension target, same as Android requires its own widget provider.

import WidgetKit
import SwiftUI

// Must match kIOSAppGroup in home_widget_service.dart exactly.
let appGroupId = "group.com.yourcompany.interfaithcalendar"

struct TodayEntry: TimelineEntry {
    let date: Date
    let nativeLabel: String
    let fajr: String
    let asr: String
    let maghrib: String
    let isha: String
    let eventTitle: String
    let eventCount: Int
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), nativeLabel: "Loading…", fajr: "--:--", asr: "--:--",
                    maghrib: "--:--", isha: "--:--", eventTitle: "", eventCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = readEntry()
        // Ask iOS to refresh again in 30 minutes; the app itself also
        // triggers WidgetCenter.shared.reloadTimelines() on open, same as
        // the Android side calls HomeWidget.updateWidget().
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> TodayEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let countStr = defaults?.string(forKey: "event_count") ?? "0"
        return TodayEntry(
            date: Date(),
            nativeLabel: defaults?.string(forKey: "native_label") ?? "",
            fajr: defaults?.string(forKey: "fajr") ?? "--:--",
            asr: defaults?.string(forKey: "asr") ?? "--:--",
            maghrib: defaults?.string(forKey: "maghrib") ?? "--:--",
            isha: defaults?.string(forKey: "isha") ?? "--:--",
            eventTitle: defaults?.string(forKey: "event_title") ?? "",
            eventCount: Int(countStr) ?? 0
        )
    }
}

struct TodayWidgetView: View {
    var entry: TodayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.nativeLabel)
                .font(.headline)
                .foregroundColor(Color(red: 0.71, green: 0.07, blue: 0.11)) // #B5121B
            HStack {
                Text("Fajr \(entry.fajr)")
                Spacer()
                Text("Asr \(entry.asr)")
            }
            .font(.caption)
            HStack {
                Text("Maghrib \(entry.maghrib)")
                Spacer()
                Text("Isha \(entry.isha)")
            }
            .font(.caption)
            Spacer(minLength: 4)
            if entry.eventCount > 0 {
                Text(entry.eventCount == 1 ? entry.eventTitle : "\(entry.eventTitle) +\(entry.eventCount - 1) more")
                    .font(.caption2)
            } else {
                Text("No events today")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        // True background transparency on iOS 17+ widgets requires the
        // "accented widget background removal" entitlement / containerBackground
        // API below; on iOS 16 and earlier, widgets always render on an opaque
        // system-provided background — this is an OS rule, not something this
        // code can override.
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct TodayWidget: Widget {
    let kind: String = "TodayWidget" // must match kIOSWidgetKind in Dart

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Today's date, prayer times, and events.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
