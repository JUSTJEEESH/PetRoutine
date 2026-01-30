import CoreData
import SwiftUI

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func fetchEntries(for petID: UUID) {
        let context = persistence.container.viewContext
        let request = CDJournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "pet.id == %@", petID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDJournalEntry.createdAt, ascending: false)]

        guard let results = try? context.fetch(request) else { return }
        entries = results.map { $0.toJournalEntry() }
    }

    func addEntry(_ entry: JournalEntry) {
        let context = persistence.container.viewContext
        let cdEntry = CDJournalEntry(context: context)
        cdEntry.id = entry.id
        cdEntry.text = entry.text
        cdEntry.photoData = entry.photoData
        cdEntry.createdAt = entry.createdAt

        let petReq = CDPet.fetchRequest()
        petReq.predicate = NSPredicate(format: "id == %@", entry.petID as CVarArg)
        if let cdPet = try? context.fetch(petReq).first {
            cdEntry.pet = cdPet
        }

        persistence.save()
        fetchEntries(for: entry.petID)
    }

    func deleteEntry(_ entry: JournalEntry) {
        let context = persistence.container.viewContext
        let request = CDJournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)

        guard let cdEntry = try? context.fetch(request).first else { return }
        context.delete(cdEntry)
        persistence.save()
        fetchEntries(for: entry.petID)
    }
}
