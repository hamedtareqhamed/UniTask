import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), courseName: "Placeholder", time: "10:00 AM", room: "Room 101")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), courseName: "Example Class", time: "11:00 AM", room: "A-501")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.dev.albazeli.unitask")
        let courseName = userDefaults?.string(forKey: "next_course_name") ?? "No Classes"
        let courseTime = userDefaults?.string(forKey: "next_course_time") ?? ""
        let courseRoom = userDefaults?.string(forKey: "next_course_room") ?? ""

        let entries = [SimpleEntry(date: Date(), courseName: courseName, time: courseTime, room: courseRoom)]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let courseName: String
    let time: String
    let room: String
}

struct WidgetExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next Class")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(entry.courseName)
                .font(.headline)
                .bold()
                .lineLimit(1)
            
            HStack {
                Image(systemName: "clock")
                Text(entry.time)
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text(entry.room)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

@main
struct WidgetExtension: Widget {
    let kind: String = "WidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("UniTask Widget")
        .description("View your next class at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
