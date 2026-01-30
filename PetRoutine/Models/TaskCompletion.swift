import Foundation

struct TaskCompletion: Identifiable, Hashable {
    let id: UUID
    let taskID: UUID
    let petID: UUID
    let completedAt: Date
    var caregiverName: String
    var notes: String?

    init(
        id: UUID = UUID(),
        taskID: UUID,
        petID: UUID,
        completedAt: Date = Date(),
        caregiverName: String = "Me",
        notes: String? = nil
    ) {
        self.id = id
        self.taskID = taskID
        self.petID = petID
        self.completedAt = completedAt
        self.caregiverName = caregiverName
        self.notes = notes
    }
}
