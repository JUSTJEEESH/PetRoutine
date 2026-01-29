import WidgetKit
import SwiftUI
import CoreData

// MARK: - Timeline Entry

struct PetTaskEntry: TimelineEntry {
    let date: Date
    let petName: String
    let nextTaskName: String?
    let nextTaskTime: String?
    let nextTaskIcon: String
    let lastCompletedTask: String?
    let lastCompletedTime: String?
    let completedCount: Int
    let totalCount: Int
}

// MARK: - Timeline Provider

struct PetTaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetTaskEntry {
        PetTaskEntry(
            date: Date(),
            petName: "Buddy",
            nextTaskName: "Morning Feed",
            nextTaskTime: "8:00 AM",
            nextTaskIcon: "fork.knife",
            lastCompletedTask: "Walk",
            lastCompletedTime: "7:00 AM",
            completedCount: 2,
            totalCount: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PetTaskEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetTaskEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> PetTaskEntry {
        // Returns a default entry; in production, read from shared Core Data store
        PetTaskEntry(
            date: Date(),
            petName: "Pet",
            nextTaskName: nil,
            nextTaskTime: nil,
            nextTaskIcon: "pawprint.fill",
            lastCompletedTask: nil,
            lastCompletedTime: nil,
            completedCount: 0,
            totalCount: 0
        )
    }
}

// MARK: - Widget Views

struct PetRoutineWidgetEntryView: View {
    var entry: PetTaskEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.caption)
                    .foregroundStyle(.accent)
                Text(entry.petName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Spacer()

            if let taskName = entry.nextTaskName {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: entry.nextTaskIcon)
                            .font(.caption)
                        Text(taskName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    if let time = entry.nextTaskTime {
                        Text(time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("All done!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }

            if entry.totalCount > 0 {
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Next task
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(.accent)
                    Text(entry.petName)
                        .fontWeight(.semibold)
                }
                .font(.caption)

                Spacer()

                if let taskName = entry.nextTaskName {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Task")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: entry.nextTaskIcon)
                            Text(taskName)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)

                        if let time = entry.nextTaskTime {
                            Text(time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("All done!")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }

            Divider()

            // Last completed
            VStack(alignment: .leading, spacing: 6) {
                Text("Last Completed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if let lastTask = entry.lastCompletedTask {
                    Text(lastTask)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let time = entry.lastCompletedTime {
                        Text(time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Nothing yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if entry.totalCount > 0 {
                    Text("\(entry.completedCount)/\(entry.totalCount) today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct PetRoutineNextTaskWidget: Widget {
    let kind = "PetRoutineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetTaskProvider()) { entry in
            PetRoutineWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pet Tasks")
        .description("See your pet's next task and progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct PetRoutineWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetRoutineNextTaskWidget()
    }
}
