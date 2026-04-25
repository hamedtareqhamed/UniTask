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
            nextTask: TaskEntryData(id: "1", title: "Project Proposal", subject: "S.E.", time: "11:59 PM", weight: "15%", type: "ASSESSMENT"),
            recentTasks: []
        )
        completion(entry)
    }

    private func fetchString(from prefs: UserDefaults?, key: String) -> String {
        if let val = prefs?.string(forKey: key), !val.isEmpty { return val }
        if let val = prefs?.string(forKey: "widgetData-\(key)"), !val.isEmpty { return val }
        return ""
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.synchronize() // Force synchronization for older iOS or TrollStore environments
        let now = Date()
        
        // --- Fetch Class Data ---
        let className = fetchString(from: userDefaults, key: "next_class_name")
        let nextClass = SimpleEntry.ClassData(
            name: className,
            code: fetchString(from: userDefaults, key: "next_class_code"),
            room: fetchString(from: userDefaults, key: "next_class_room"),
            type: fetchString(from: userDefaults, key: "next_class_type"),
            countdown: fetchString(from: userDefaults, key: "next_class_countdown")
        )
        
        // --- Fetch Task Data ---
        let taskTitle = fetchString(from: userDefaults, key: "next_task_title")
        let nextTask = TaskEntryData(
            id: "primary",
            title: taskTitle,
            subject: fetchString(from: userDefaults, key: "next_task_subject"),
            time: "", 
            weight: "", 
            type: fetchString(from: userDefaults, key: "next_task_type")
        )
        
        // --- Fetch Recent Tasks ---
        var recentTasks: [TaskEntryData] = []
        var count = userDefaults?.integer(forKey: "task_count") ?? 0
        if count == 0 { count = userDefaults?.integer(forKey: "widgetData-task_count") ?? 0 }
        
        for i in 0..<min(count, 5) {
            let tTitle = fetchString(from: userDefaults, key: "task_\(i)_title")
            if !tTitle.isEmpty {
                recentTasks.append(TaskEntryData(
                    id: "\(i)",
                    title: tTitle,
                    subject: fetchString(from: userDefaults, key: "task_\(i)_subject"),
                    time: fetchString(from: userDefaults, key: "task_\(i)_time"),
                    weight: fetchString(from: userDefaults, key: "task_\(i)_weight"),
                    type: fetchString(from: userDefaults, key: "task_\(i)_type")
                ))
            }
        }

        let entry = SimpleEntry(
            date: now,
            nextClass: className == "" || className == "No Classes" ? nil : nextClass,
            nextTask: taskTitle == "" || taskTitle == "No Tasks" ? nil : nextTask,
            recentTasks: recentTasks
        )

        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Compact UI Components

struct ClassBadge: View {
    let type: String
    var body: some View {
        Text(type)
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(4)
    }
}

// MARK: - Main Views

struct ClassWidgetView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 8) {
            HStack {
                Text("NEXT CLASS").font(.system(size: 10, weight: .black)).foregroundColor(.blue)
                Spacer()
                if let data = entry.nextClass { ClassBadge(type: data.type) }
            }
            
            if let data = entry.nextClass {
                Text(data.name)
                    .font(.system(size: family == .systemSmall ? 15 : 18, weight: .bold))
                    .lineLimit(family == .systemSmall ? 2 : 1)
                
                Text(data.code)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Label(data.room, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 11))
                    Text(data.countdown)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.blue)
                }
            } else {
                Text("Free Time").font(.system(size: 16, weight: .bold)).foregroundColor(.secondary).padding(.top, 10)
                Spacer()
            }
        }
        .padding(family == .systemSmall ? 12 : 16)
        .widgetBackground(.clear)
    }
}

struct TaskWidgetView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DEADLINES")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.orange)
            
            if let task = entry.nextTask {
                if family == .systemSmall {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title).font(.system(size: 14, weight: .bold)).lineLimit(2)
                        Text(task.subject).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
                        Spacer()
                        Text(userDefaultsKey("next_task_countdown")).font(.system(size: 14, weight: .heavy)).foregroundColor(.orange)
                    }
                } else {
                    // Medium or Large
                    ForEach(entry.recentTasks.prefix(family == .systemMedium ? 2 : 5)) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(item.title).font(.system(size: 12, weight: .bold)).lineLimit(1)
                                Text(item.subject).font(.system(size: 9)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(item.time).font(.system(size: 10, weight: .medium)).foregroundColor(.orange)
                        }
                        Divider().opacity(0.1)
                    }
                    Spacer()
                }
            } else {
                Text("All Done!").font(.system(size: 16, weight: .bold)).foregroundColor(.green).padding(.top, 10)
                Spacer()
            }
        }
        .padding(12)
        .widgetBackground(.clear)
    }
    
    func userDefaultsKey(_ key: String) -> String {
        let userDefaults = UserDefaults(suiteName: "group.dev.albazeli.unitask")
        if let val = userDefaults?.string(forKey: key), !val.isEmpty { return val }
        return userDefaults?.string(forKey: "widgetData-\(key)") ?? ""
    }
}

// MARK: - Lock Screen Views

struct LockScreenTaskView: View {
    var entry: SimpleEntry
    var body: some View {
        VStack(alignment: .leading) {
            if let task = entry.nextTask {
                Text(task.title).font(.headline).lineLimit(1)
                Text(userDefaultsKey("next_task_countdown")).font(.caption).bold()
            } else {
                Text("No Tasks")
            }
        }
    }
    func userDefaultsKey(_ key: String) -> String {
        let userDefaults = UserDefaults(suiteName: "group.dev.albazeli.unitask")
        if let val = userDefaults?.string(forKey: key), !val.isEmpty { return val }
        return userDefaults?.string(forKey: "widgetData-\(key)") ?? ""
    }
}

struct LockScreenClassView: View {
    var entry: SimpleEntry
    var body: some View {
        HStack {
            Image(systemName: "book.fill")
            if let data = entry.nextClass {
                Text(data.countdown).bold()
            } else {
                Text("--:--")
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
    let kind: String = "dev.albazeli.unitask.classWidget" // Must match reload logic
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ClassWidgetView(entry: entry)
        }
        .configurationDisplayName("Classes")
        .description("Your next lecture or lab.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TaskWidget: Widget {
    let kind: String = "dev.albazeli.unitask.taskWidget" // Must match reload logic
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TaskWidgetView(entry: entry)
        }
        .configurationDisplayName("Assessments")
        .description("Academic deadlines.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct LockScreenTaskWidget: Widget {
    let kind: String = "dev.albazeli.unitask.lockTask"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenTaskView(entry: entry)
        }
        .configurationDisplayName("Lock Deadline")
        .description("Task countdown.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockScreenClassWidget: Widget {
    let kind: String = "dev.albazeli.unitask.lockClass"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenClassView(entry: entry)
        }
        .configurationDisplayName("Lock Class")
        .description("Class countdown.")
        .supportedFamilies([.accessoryInline])
    }
}
