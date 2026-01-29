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
        case .medication: "pill.fill"
        case .grooming: "scissors"
        case .custom: "star.fill"
        }
    }
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
    var petID: UUID?
    var name: String
    var taskType: TaskType
    var frequencyType: FrequencyType
    var frequencyValue: String?
    var scheduledTimes: [Date]
    var notes: String?
    var isEnabled: Bool
    var notifyEnabled: Bool
    var routineID: UUID?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        petID: UUID? = nil,
        name: String = "",
        taskType: TaskType = .custom,
        frequencyType: FrequencyType = .daily,
        frequencyValue: String? = nil,
        scheduledTimes: [Date] = [],
        notes: String? = nil,
        isEnabled: Bool = true,
        notifyEnabled: Bool = true,
        routineID: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.petID = petID
        self.name = name
        self.taskType = taskType
        self.frequencyType = frequencyType
        self.frequencyValue = frequencyValue
        self.scheduledTimes = scheduledTimes
        self.notes = notes
        self.isEnabled = isEnabled
        self.notifyEnabled = notifyEnabled
        self.routineID = routineID
        self.createdAt = createdAt
    }
}
