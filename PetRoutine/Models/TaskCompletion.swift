import Foundation

struct TaskCompletion: Identifiable, Hashable {
    let id: UUID
    var careTaskID: UUID?
    var completedAt: Date
    var caregiverName: String
    var notes: String?

    init(
        id: UUID = UUID(),
        careTaskID: UUID? = nil,
        completedAt: Date = Date(),
        caregiverName: String = "Me",
        notes: String? = nil
    ) {
        self.id = id
        self.careTaskID = careTaskID
        self.completedAt = completedAt
        self.caregiverName = caregiverName
        self.notes = notes
    }
}
