import Foundation

struct Routine: Identifiable, Hashable {
    let id: UUID
    var name: String
    var isEnabled: Bool
    var notes: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        isEnabled: Bool = true,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.notes = notes
        self.createdAt = createdAt
    }
}
