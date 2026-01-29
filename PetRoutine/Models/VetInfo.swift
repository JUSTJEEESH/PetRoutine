import Foundation

struct VetInfo: Identifiable, Hashable {
    let id: UUID
    var petID: UUID?
    var name: String
    var phone: String
    var address: String
    var notes: String

    init(
        id: UUID = UUID(),
        petID: UUID? = nil,
        name: String = "",
        phone: String = "",
        address: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.petID = petID
        self.name = name
        self.phone = phone
        self.address = address
        self.notes = notes
    }
}
