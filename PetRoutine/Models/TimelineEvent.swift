import Foundation

enum TimelineEventType {
    case taskCompleted(taskName: String, taskType: TaskType, caregiverName: String)
    case journalEntry(text: String, hasPhoto: Bool)
}

struct TimelineEvent: Identifiable {
    let id: UUID
    let petID: UUID
    let date: Date
    let eventType: TimelineEventType

    var displayTitle: String {
        switch eventType {
        case .taskCompleted(let taskName, _, let caregiver):
            "\(taskName) — \(caregiver)"
        case .journalEntry(let text, _):
            text
        }
    }

    var icon: String {
        switch eventType {
        case .taskCompleted(_, let taskType, _):
            taskType.icon
        case .journalEntry(_, let hasPhoto):
            hasPhoto ? "photo.fill" : "note.text"
        }
    }
}
