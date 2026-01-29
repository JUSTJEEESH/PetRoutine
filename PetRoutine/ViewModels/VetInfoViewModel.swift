import CoreData
import SwiftUI

@MainActor
final class VetInfoViewModel: ObservableObject {
    @Published var vetInfo: VetInfo?

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func fetchVetInfo(for petID: UUID) {
        let context = persistence.container.viewContext
        let request = CDVetInfo.fetchRequest()
        request.predicate = NSPredicate(format: "pet.id == %@", petID as CVarArg)
        request.fetchLimit = 1

        do {
            vetInfo = try context.fetch(request).first?.toVetInfo()
        } catch {
            print("Fetch vet info error: \(error.localizedDescription)")
        }
    }

    func saveVetInfo(_ info: VetInfo) {
        let context = persistence.container.viewContext

        let request = CDVetInfo.fetchRequest()
        request.predicate = NSPredicate(format: "pet.id == %@", (info.petID ?? UUID()) as CVarArg)

        do {
            let existing = try context.fetch(request).first
            if let existing {
                existing.update(from: info, in: context)
            } else {
                let cdInfo = CDVetInfo(context: context)
                cdInfo.update(from: info, in: context)
            }
            persistence.save()
            vetInfo = info
        } catch {
            print("Save vet info error: \(error.localizedDescription)")
        }
    }
}
