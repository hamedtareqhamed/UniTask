import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
    let detail1: String
    let detail2: String
    let countdown: String
    let tasks: [TaskEntry]
}

struct TaskEntry: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let weight: String
    let type: String
}

struct BaseProvider: TimelineProvider {
    let widgetKind: String

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), title: "Loading...", subtitle: "", detail1: "", detail2: "", countdown: "", tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), title: "Sample", subtitle: "Subject", detail1: "A-101", detail2: "LEC", countdown: "2h", tasks: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.dev.albazeli.unitask")
        var entries: [SimpleEntry] = []
        
        let now = Date()
        
        if widgetKind == "ClassWidget" {
            let entry = SimpleEntry(
                date: now,
                title: userDefaults?.string(forKey: "next_class_name") ?? "No Classes",
                subtitle: userDefaults?.string(forKey: "next_class_code") ?? "",
                detail1: userDefaults?.string(forKey: "next_class_room") ?? "TBA",
                detail2: userDefaults?.string(forKey: "next_class_type") ?? "",
                countdown: userDefaults?.string(forKey: "next_class_countdown") ?? "",
                tasks: []
            )
            entries.append(entry)
        } else if widgetKind == "TaskWidget" {
            var tasks: [TaskEntry] = []
            let count = userDefaults?.integer(forKey: "task_count") ?? 0
            for i in 0..<min(count, 5) {
                tasks.append(TaskEntry(
                    title: userDefaults?.string(forKey: "task_\(i)_title") ?? "",
                    time: userDefaults?.string(forKey: "task_\(i)_time") ?? "",
                    weight: userDefaults?.string(forKey: "task_\(i)_weight") ?? "",
                    type: userDefaults?.string(forKey: "task_\(i)_type") ?? ""
                ))
            }
            
            let entry = SimpleEntry(
                date: now,
                title: userDefaults?.string(forKey: "next_task_title") ?? "No Tasks",
                subtitle: userDefaults?.string(forKey: "next_task_subject") ?? "",
                detail1: userDefaults?.string(forKey: "next_task_code") ?? "",
                detail2: "",
                countdown: userDefaults?.string(forKey: "next_task_countdown") ?? "",
                tasks: tasks
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(for: .widget) { color }
        } else {
            return self.background(color)
        }
    }
}

// --- Views ---

struct ClassWidgetView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT CLASS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
            
            Text(entry.title)
                .font(.headline)
                .bold()
                .lineLimit(1)
            
            Text(entry.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()
            
            HStack {
                Label(entry.detail1, systemImage: "mappin.and.ellipse")
                Spacer()
                Text(entry.countdown)
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                    .bold()
            }
            .font(.system(size: 12))
        }
        .widgetBackground(Color.black)
    }
}

struct TaskSmallWidgetView: View {
    var entry: SimpleEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(entry.subtitle)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.orange)
            
            Text(entry.title)
                .font(.system(size: 14, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(entry.countdown)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.orange)
        }
        .widgetBackground(Color.black)
    }
}

struct TaskLargeWidgetView: View {
    var entry: SimpleEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("UPCOMING WORK")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.purple)
            
            ForEach(entry.tasks) { task in
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Text(task.title)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                        Spacer()
                        Text(task.weight)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    HStack {
                        Text(task.type)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(task.time)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                Divider().opacity(0.1)
            }
            if entry.tasks.isEmpty {
                Text("No upcoming tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .widgetBackground(Color.black)
    }
}

struct LockScreenTaskView: View {
    var entry: SimpleEntry
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.title).font(.headline).lineLimit(1)
            Text("\(entry.detail1) • \(entry.countdown)").font(.caption)
        }
    }
}

struct LockScreenClassView: View {
    var entry: SimpleEntry
    var body: some View {
        HStack {
            Image(systemName: "book.fill")
            Text(entry.detail1)
            Text(entry.countdown).bold()
        }
    }
}

// --- Widgets ---

struct ClassWidget: Widget {
    let kind: String = "ClassWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BaseProvider(widgetKind: kind)) { entry in
            ClassWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Class")
        .description("Countdown to your next lesson.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TaskWidget: Widget {
    let kind: String = "TaskWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BaseProvider(widgetKind: kind)) { entry in
            if entry.tasks.count > 1 {
                TaskLargeWidgetView(entry: entry)
            } else {
                TaskSmallWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Tasks & Work")
        .description("Keep track of your deadlines.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@available(iOS 16.0, *)
struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BaseProvider(widgetKind: "TaskWidget")) { entry in
            LockScreenTaskView(entry: entry)
        }
        .configurationDisplayName("Lock Screen Task")
        .description("Next deadline at a glance.")
        .supportedFamilies([.accessoryRectangular])
    }
}

@available(iOS 16.0, *)
struct LockScreenClassWidget: Widget {
    let kind: String = "LockScreenClassWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BaseProvider(widgetKind: "ClassWidget")) { entry in
            LockScreenClassView(entry: entry)
        }
        .configurationDisplayName("Lock Screen Class")
        .description("Next class info.")
        .supportedFamilies([.accessoryInline])
    }
}

@main
struct UniTaskWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        ClassWidget()
        TaskWidget()
        if #available(iOS 16.0, *) {
            LockScreenWidget()
            LockScreenClassWidget()
        }
    }
}
