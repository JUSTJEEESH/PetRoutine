import Foundation

struct VetInfo: Identifiable, Hashable {
    let id: UUID
    let petID: UUID
    var name: String?
    var phone: String?
    var address: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        petID: UUID,
        name: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.petID = petID
        self.name = name
        self.phone = phone
        self.address = address
        self.notes = notes
    }
}
