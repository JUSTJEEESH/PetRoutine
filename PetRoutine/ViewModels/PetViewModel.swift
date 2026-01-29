import CoreData
import SwiftUI
import Combine

@MainActor
final class PetViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var selectedPet: Pet?

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        fetchPets()
    }

    func fetchPets() {
        let context = persistence.container.viewContext
        let request = CDPet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDPet.sortOrder, ascending: true)]

        do {
            let results = try context.fetch(request)
            pets = results.map { $0.toPet() }
            if selectedPet == nil || !pets.contains(where: { $0.id == selectedPet?.id }) {
                selectedPet = pets.first
            }
        } catch {
            print("Fetch pets error: \(error.localizedDescription)")
        }
    }

    func addPet(_ pet: Pet) {
        let context = persistence.container.viewContext
        let cdPet = CDPet(context: context)
        cdPet.update(from: pet)
        persistence.save()
        fetchPets()
        selectedPet = pet
    }

    func updatePet(_ pet: Pet) {
        let context = persistence.container.viewContext
        let request = CDPet.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", pet.id as CVarArg)

        do {
            if let cdPet = try context.fetch(request).first {
                cdPet.update(from: pet)
                persistence.save()
                fetchPets()
            }
        } catch {
            print("Update pet error: \(error.localizedDescription)")
        }
    }

    func deletePet(_ pet: Pet) {
        let context = persistence.container.viewContext
        let request = CDPet.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", pet.id as CVarArg)

        do {
            if let cdPet = try context.fetch(request).first {
                context.delete(cdPet)
                persistence.save()
                fetchPets()
            }
        } catch {
            print("Delete pet error: \(error.localizedDescription)")
        }
    }

    var canAddPet: Bool {
        let storeKit = StoreKitService.shared
        return pets.count < 1 || storeKit.proUnlocked
    }
}
