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

        if let cdVetInfo = try? context.fetch(request).first {
            vetInfo = cdVetInfo.toVetInfo()
        } else {
            vetInfo = nil
        }
    }

    func saveVetInfo(_ info: VetInfo) {
        let context = persistence.container.viewContext
        let request = CDVetInfo.fetchRequest()
        request.predicate = NSPredicate(format: "pet.id == %@", info.petID as CVarArg)

        let cdVetInfo: CDVetInfo
        if let existing = try? context.fetch(request).first {
            cdVetInfo = existing
        } else {
            cdVetInfo = CDVetInfo(context: context)
            cdVetInfo.id = info.id

            let petReq = CDPet.fetchRequest()
            petReq.predicate = NSPredicate(format: "id == %@", info.petID as CVarArg)
            if let cdPet = try? context.fetch(petReq).first {
                cdVetInfo.pet = cdPet
            }
        }

        cdVetInfo.name = info.name
        cdVetInfo.phone = info.phone
        cdVetInfo.address = info.address
        cdVetInfo.notes = info.notes

        persistence.save()
        fetchVetInfo(for: info.petID)
    }
}
