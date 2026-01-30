import CoreData
import SwiftUI

@MainActor
final class HouseholdViewModel: ObservableObject {
    @Published var household: Household?
    @Published var caregivers: [Caregiver] = []

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func fetchHousehold() {
        let context = persistence.container.viewContext
        let request = CDHousehold.fetchRequest()
        request.fetchLimit = 1

        if let cdHousehold = try? context.fetch(request).first {
            household = cdHousehold.toHousehold()
            caregivers = household?.caregivers ?? []
        }
    }

    func createHousehold(name: String) {
        let context = persistence.container.viewContext
        let cdHousehold = CDHousehold(context: context)
        cdHousehold.id = UUID()
        cdHousehold.name = name
        cdHousehold.createdAt = Date()
        persistence.save()
        fetchHousehold()
    }

    func addCaregiver(_ caregiver: Caregiver) {
        let context = persistence.container.viewContext

        if household == nil {
            createHousehold(name: "My Household")
        }

        let request = CDHousehold.fetchRequest()
        request.fetchLimit = 1
        guard let cdHousehold = try? context.fetch(request).first else { return }

        let cdCaregiver = CDCaregiver(context: context)
        cdCaregiver.id = caregiver.id
        cdCaregiver.name = caregiver.name
        cdCaregiver.role = caregiver.role.rawValue
        cdCaregiver.isTemporary = caregiver.isTemporary
        cdCaregiver.expiresAt = caregiver.expiresAt
        cdCaregiver.createdAt = caregiver.createdAt
        cdCaregiver.household = cdHousehold

        persistence.save()
        fetchHousehold()
    }

    func removeCaregiver(_ caregiver: Caregiver) {
        let context = persistence.container.viewContext
        let request = CDCaregiver.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", caregiver.id as CVarArg)

        guard let cdCaregiver = try? context.fetch(request).first else { return }
        context.delete(cdCaregiver)
        persistence.save()
        fetchHousehold()
    }
}
