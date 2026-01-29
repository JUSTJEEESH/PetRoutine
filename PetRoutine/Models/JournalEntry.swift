import Foundation

struct JournalEntry: Identifiable, Hashable {
    let id: UUID
    var petID: UUID?
    var text: String
    var photoData: Data?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        petID: UUID? = nil,
        text: String = "",
        photoData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.petID = petID
        self.text = text
        self.photoData = photoData
        self.createdAt = createdAt
    }
}
