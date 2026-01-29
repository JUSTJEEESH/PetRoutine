import Foundation

enum PetType: String, CaseIterable, Identifiable, Codable {
    case dog
    case cat

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dog: "Dog"
        case .cat: "Cat"
        }
    }

    var icon: String {
        switch self {
        case .dog: "dog.fill"
        case .cat: "cat.fill"
        }
    }
}

enum AgeCategory: String, CaseIterable, Identifiable, Codable {
    case puppy
    case adult
    case senior

    var id: String { rawValue }

    func displayName(for petType: PetType) -> String {
        switch (self, petType) {
        case (.puppy, .dog): "Puppy"
        case (.puppy, .cat): "Kitten"
        case (.adult, _): "Adult"
        case (.senior, _): "Senior"
        }
    }
}

struct Pet: Identifiable, Hashable {
    let id: UUID
    var name: String
    var petType: PetType
    var ageCategory: AgeCategory
    var photoData: Data?
    var sortOrder: Int16
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        petType: PetType = .dog,
        ageCategory: AgeCategory = .adult,
        photoData: Data? = nil,
        sortOrder: Int16 = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.petType = petType
        self.ageCategory = ageCategory
        self.photoData = photoData
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
