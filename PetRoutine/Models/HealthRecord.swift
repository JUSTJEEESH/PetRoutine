import Foundation

enum HealthRecordType: String, CaseIterable, Identifiable, Codable {
    case vaccination
    case medication
    case procedure

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vaccination: "Vaccination"
        case .medication: "Medication"
        case .procedure: "Procedure"
        }
    }

    var icon: String {
        switch self {
        case .vaccination: "syringe.fill"
        case .medication: "pills.fill"
        case .procedure: "cross.case.fill"
        }
    }
}

struct HealthRecord: Identifiable, Hashable {
    let id: UUID
    var petID: UUID
    var name: String
    var recordType: HealthRecordType
    var dateAdministered: Date
    var nextDueDate: Date?
    var notes: String?
    var reminderEnabled: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        petID: UUID,
        name: String = "",
        recordType: HealthRecordType = .vaccination,
        dateAdministered: Date = Date(),
        nextDueDate: Date? = nil,
        notes: String? = nil,
        reminderEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.petID = petID
        self.name = name
        self.recordType = recordType
        self.dateAdministered = dateAdministered
        self.nextDueDate = nextDueDate
        self.notes = notes
        self.reminderEnabled = reminderEnabled
        self.createdAt = createdAt
    }

    var isOverdue: Bool {
        guard let dueDate = nextDueDate else { return false }
        return dueDate < Date()
    }

    var isDueSoon: Bool {
        guard let dueDate = nextDueDate else { return false }
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return dueDate <= twoWeeksFromNow && dueDate >= Date()
    }
}
