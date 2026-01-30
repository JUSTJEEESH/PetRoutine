import CoreData
import SwiftUI

@MainActor
final class PetViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var selectedPet: Pet?
    @Published var showAllPets: Bool = true

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    var canAddPet: Bool {
        StoreKitService.shared.proUnlocked || pets.count < 1
    }

    func fetchPets() {
        let context = persistence.container.viewContext
        let request = CDPet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDPet.sortOrder, ascending: true)]

        guard let results = try? context.fetch(request) else { return }
        pets = results.map { $0.toPet() }

        if selectedPet == nil, let first = pets.first {
            selectedPet = first
        }
        if let sel = selectedPet, !pets.contains(where: { $0.id == sel.id }) {
            selectedPet = pets.first
        }
    }

    func addPet(_ pet: Pet) {
        let context = persistence.container.viewContext
        let cdPet = CDPet(context: context)
        cdPet.id = pet.id
        cdPet.name = pet.name
        cdPet.petType = pet.petType.rawValue
        cdPet.ageCategory = pet.ageCategory.rawValue
        cdPet.photoData = pet.photoData
        cdPet.birthday = pet.birthday
        cdPet.sortOrder = pet.sortOrder
        cdPet.createdAt = pet.createdAt
        persistence.save()
        fetchPets()
        selectedPet = pets.first(where: { $0.id == pet.id })
    }

    func updatePet(_ pet: Pet) {
        let context = persistence.container.viewContext
        let request = CDPet.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", pet.id as CVarArg)

        guard let cdPet = try? context.fetch(request).first else { return }
        cdPet.name = pet.name
        cdPet.petType = pet.petType.rawValue
        cdPet.ageCategory = pet.ageCategory.rawValue
        cdPet.photoData = pet.photoData
        cdPet.birthday = pet.birthday
        cdPet.sortOrder = pet.sortOrder
        persistence.save()
        fetchPets()
    }

    func deletePet(_ pet: Pet) {
        let context = persistence.container.viewContext
        let request = CDPet.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", pet.id as CVarArg)

        guard let cdPet = try? context.fetch(request).first else { return }
        context.delete(cdPet)
        persistence.save()
        fetchPets()
    }

    func petFor(id: UUID) -> Pet? {
        pets.first(where: { $0.id == id })
    }
}
