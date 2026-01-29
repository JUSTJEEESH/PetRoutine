import CoreData
import SwiftUI

@MainActor
final class HouseholdViewModel: ObservableObject {
    @Published var household: Household?
    @Published var caregivers: [Caregiver] = []

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        fetchHousehold()
    }

    func fetchHousehold() {
        let context = persistence.container.viewContext
        let request = CDHousehold.fetchRequest()
        request.fetchLimit = 1

        do {
            let result = try context.fetch(request).first
            household = result?.toHousehold()

            if let cdHousehold = result,
               let cdCaregivers = cdHousehold.caregivers as? Set<CDCaregiver> {
                caregivers = cdCaregivers
                    .map { $0.toCaregiver() }
                    .filter { !$0.isExpired }
                    .sorted { $0.createdAt < $1.createdAt }
            } else {
                caregivers = []
            }
        } catch {
            print("Fetch household error: \(error.localizedDescription)")
        }
    }

    func createHousehold(name: String) {
        let context = persistence.container.viewContext
        let cdHousehold = CDHousehold(context: context)
        cdHousehold.id = UUID()
        cdHousehold.name = name
        cdHousehold.createdAt = Date()

        let owner = CDCaregiver(context: context)
        owner.id = UUID()
        owner.name = "Me"
        owner.role = CaregiverRole.owner.rawValue
        owner.isTemporary = false
        owner.createdAt = Date()
        owner.household = cdHousehold

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

        do {
            if let cdHousehold = try context.fetch(request).first {
                let cdCaregiver = CDCaregiver(context: context)
                cdCaregiver.update(from: caregiver)
                cdCaregiver.household = cdHousehold
                persistence.save()
                fetchHousehold()
            }
        } catch {
            print("Add caregiver error: \(error.localizedDescription)")
        }
    }

    func removeCaregiver(_ caregiver: Caregiver) {
        let context = persistence.container.viewContext
        let request = CDCaregiver.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", caregiver.id as CVarArg)

        do {
            if let cdCaregiver = try context.fetch(request).first {
                context.delete(cdCaregiver)
                persistence.save()
                fetchHousehold()
            }
        } catch {
            print("Remove caregiver error: \(error.localizedDescription)")
        }
    }

    func updateCaregiver(_ caregiver: Caregiver) {
        let context = persistence.container.viewContext
        let request = CDCaregiver.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", caregiver.id as CVarArg)

        do {
            if let cdCaregiver = try context.fetch(request).first {
                cdCaregiver.update(from: caregiver)
                persistence.save()
                fetchHousehold()
            }
        } catch {
            print("Update caregiver error: \(error.localizedDescription)")
        }
    }

    var activeCaregiverNames: [String] {
        caregivers
            .filter { !$0.isExpired }
            .map(\.name)
    }
}
