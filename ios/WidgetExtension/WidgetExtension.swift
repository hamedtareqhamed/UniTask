import WidgetKit
import SwiftUI

// MARK: - Models

struct TaskEntryData: Identifiable, Codable {
    let id: String
    let title: String
    let subject: String
    let time: String
    let weight: String
    let type: String
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let nextClass: ClassData?
    let nextTask: TaskEntryData?
    let recentTasks: [TaskEntryData]
    
    struct ClassData: Codable {
        let name: String
        let code: String
        let room: String
        let type: String
        let countdown: String
    }
}

// MARK: - View Compatibility Extension

extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(.background, for: .widget)
        } else {
            return self.background(color)
        }
    }
}

// MARK: - Provider

struct Provider: TimelineProvider {
    let suiteName = "group.dev.albazeli.unitask"
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), nextClass: nil, nextTask: nil, recentTasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(
            date: Date(),
            nextClass: SimpleEntry.ClassData(name: "Data Structures", code: "CS201", room: "Lab 4", type: "LAB", countdown: "2h 15m"),
            nextTask: TaskEntryData(id: "1", title: "Project Proposal", subject: "Software Engineering", time: "11:59 PM", weight: "15%", type: "ASSESSMENT"),
            recentTasks: []
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: suiteName)
        let now = Date()
        
        // Fetch Class Data
        let nextClass = SimpleEntry.ClassData(
            name: userDefaults?.string(forKey: "next_class_name") ?? "",
            code: userDefaults?.string(forKey: "next_class_code") ?? "",
            room: userDefaults?.string(forKey: "next_class_room") ?? "",
            type: userDefaults?.string(forKey: "next_class_type") ?? "",
            countdown: userDefaults?.string(forKey: "next_class_countdown") ?? ""
        )
        
        // Fetch Task Data
        let nextTask = TaskEntryData(
            id: "primary",
            title: userDefaults?.string(forKey: "next_task_title") ?? "",
            subject: userDefaults?.string(forKey: "next_task_subject") ?? "",
            time: userDefaults?.string(forKey: "next_task_time") ?? "",
            weight: userDefaults?.string(forKey: "next_task_weight") ?? "",
            type: userDefaults?.string(forKey: "next_task_type") ?? ""
        )
        
        // Fetch Recent Tasks
        var recentTasks: [TaskEntryData] = []
        let count = userDefaults?.integer(forKey: "task_count") ?? 0
        for i in 0..<min(count, 3) {
            recentTasks.append(TaskEntryData(
                id: "\(i)",
                title: userDefaults?.string(forKey: "task_\(i)_title") ?? "",
                subject: userDefaults?.string(forKey: "task_\(i)_subject") ?? "",
                time: userDefaults?.string(forKey: "task_\(i)_time") ?? "",
                weight: userDefaults?.string(forKey: "task_\(i)_weight") ?? "",
                type: userDefaults?.string(forKey: "task_\(i)_type") ?? ""
            ))
        }

        let entry = SimpleEntry(
            date: now,
            nextClass: nextClass.name.isEmpty ? nil : nextClass,
            nextTask: nextTask.title.isEmpty ? nil : nextTask,
            recentTasks: recentTasks
        )

        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Views

struct ClassWidgetView: View {
    var entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT CLASS").font(.system(size: 10, weight: .black)).foregroundColor(.blue).opacity(0.8)
            
            if let data = entry.nextClass {
                Text(data.name).font(.system(size: 16, weight: .bold)).lineLimit(1)
                Text("\(data.code) • \(data.type)").font(.system(size: 12)).foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Label(data.room, systemImage: "mappin.circle.fill")
                    Spacer()
                    Text(data.countdown).bold().foregroundColor(.blue)
                }
                .font(.system(size: 12))
            } else {
                Text("No Classes Scheduled").font(.system(size: 14)).foregroundColor(.secondary).padding(.top, 4)
                Spacer()
            }
        }
        .widgetBackground(.clear)
    }
}

struct TaskWidgetView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DEADLINES").font(.system(size: 10, weight: .black)).foregroundColor(.orange)
            
            if let task = entry.nextTask {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title).font(.system(size: 14, weight: .bold)).lineLimit(family == .systemSmall ? 2 : 1)
                    Text(task.subject).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
                }
                
                if family != .systemSmall {
                    ForEach(entry.recentTasks) { item in
                        HStack {
                            Circle().fill(Color.orange).frame(width: 6, height: 6)
                            Text(item.title).font(.system(size: 11)).lineLimit(1)
                            Spacer()
                            Text(item.time).font(.system(size: 10)).foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    if family != .systemSmall {
                        Text(task.type).font(.system(size: 10, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.orange.opacity(0.1)).cornerRadius(4)
                    }
                    Spacer()
                    Text(userDefaultsCountdown()).font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
                }
            } else {
                Text("All Caught Up!").font(.system(size: 14)).foregroundColor(.secondary).padding(.top, 4)
                Spacer()
            }
        }
        .widgetBackground(.clear)
    }
    
    func userDefaultsCountdown() -> String {
        let userDefaults = UserDefaults(suiteName: "group.dev.albazeli.unitask")
        return userDefaults?.string(forKey: "next_task_countdown") ?? ""
    }
}

// MARK: - Lock Screen Views

struct LockScreenTaskView: View {
    var entry: SimpleEntry
    var body: some View {
        VStack(alignment: .leading) {
            if let task = entry.nextTask {
                Text(task.title).font(.headline).lineLimit(1)
                Text(userDefaultsCountdown()).font(.caption).bold()
            } else {
                Text("No Deadlines").italic()
            }
        }
    }
    
    func userDefaultsCountdown() -> String {
        let userDefaults = UserDefaults(suiteName: "group.dev.albazeli.unitask")
        return userDefaults?.string(forKey: "next_task_countdown") ?? ""
    }
}

struct LockScreenClassView: View {
    var entry: SimpleEntry
    var body: some View {
        HStack {
            Image(systemName: "book.fill")
            if let data = entry.nextClass {
                Text(data.room).bold()
                Text(data.countdown)
            } else {
                Text("Free Time")
            }
        }
    }
}

// MARK: - Widget Bundle

@main
struct UniTaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClassWidget()
        TaskWidget()
        LockScreenTaskWidget()
        LockScreenClassWidget()
    }
}

// MARK: - Widget Definitions

struct ClassWidget: Widget {
    let kind: String = "dev.albazeli.unitask.classWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ClassWidgetView(entry: entry)
        }
        .configurationDisplayName("Class Schedule")
        .description("Quick view of your next class.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TaskWidget: Widget {
    let kind: String = "dev.albazeli.unitask.taskWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TaskWidgetView(entry: entry)
        }
        .configurationDisplayName("Tasks & Deadlines")
        .description("Track your upcoming academic work.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct LockScreenTaskWidget: Widget {
    let kind: String = "dev.albazeli.unitask.lockTask"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenTaskView(entry: entry)
        }
        .configurationDisplayName("Next Deadline")
        .description("View your next task on Lock Screen.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockScreenClassWidget: Widget {
    let kind: String = "dev.albazeli.unitask.lockClass"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenClassView(entry: entry)
        }
        .configurationDisplayName("Next Class")
        .description("Your next location at a glance.")
        .supportedFamilies([.accessoryInline])
    }
}
