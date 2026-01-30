import Foundation

enum TaskType: String, CaseIterable, Identifiable, Codable {
    case feeding
    case walk
    case medication
    case grooming
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .feeding: "Feeding"
        case .walk: "Walk"
        case .medication: "Medication"
        case .grooming: "Grooming"
        case .custom: "Custom"
        }
    }

    var icon: String {
        switch self {
        case .feeding: "fork.knife"
        case .walk: "figure.walk"
        case .medication: "pills.fill"
        case .grooming: "scissors"
        case .custom: "star.fill"
        }
    }

    var defaultName: String { displayName }
}

enum FrequencyType: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekly
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .custom: "Custom"
        }
    }
}

struct CareTask: Identifiable, Hashable {
    let id: UUID
    var name: String
    var taskType: TaskType
    var frequencyType: FrequencyType
    var frequencyValue: String?
    var scheduledTimes: [Date]
    var isEnabled: Bool
    var notifyEnabled: Bool
    var notes: String?
    var petIDs: [UUID]
    var petNotes: [String: String]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        taskType: TaskType = .custom,
        frequencyType: FrequencyType = .daily,
        frequencyValue: String? = nil,
        scheduledTimes: [Date] = [],
        isEnabled: Bool = true,
        notifyEnabled: Bool = true,
        notes: String? = nil,
        petIDs: [UUID] = [],
        petNotes: [String: String] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.taskType = taskType
        self.frequencyType = frequencyType
        self.frequencyValue = frequencyValue
        self.scheduledTimes = scheduledTimes
        self.isEnabled = isEnabled
        self.notifyEnabled = notifyEnabled
        self.notes = notes
        self.petIDs = petIDs
        self.petNotes = petNotes
        self.createdAt = createdAt
    }

    var earliestTime: Date? {
        scheduledTimes.sorted().first
    }

    func shouldShowToday() -> Bool {
        guard isEnabled else { return false }
        switch frequencyType {
        case .daily:
            return true
        case .weekly:
            guard let value = frequencyValue else { return true }
            let today = Calendar.current.component(.weekday, from: Date())
            return value.split(separator: ",").contains(String(today).prefix(10))
        case .custom:
            return true
        }
    }
}
