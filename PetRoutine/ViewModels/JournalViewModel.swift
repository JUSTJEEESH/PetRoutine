import CoreData
import SwiftUI

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func fetchEntries(for petID: UUID?) {
        let context = persistence.container.viewContext
        let request = CDJournalEntry.fetchRequest()

        if let petID {
            request.predicate = NSPredicate(format: "pet.id == %@", petID as CVarArg)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDJournalEntry.createdAt, ascending: false)]

        do {
            entries = try context.fetch(request).map { $0.toJournalEntry() }
        } catch {
            print("Fetch journal entries error: \(error.localizedDescription)")
        }
    }

    func addEntry(_ entry: JournalEntry) {
        let context = persistence.container.viewContext
        let cdEntry = CDJournalEntry(context: context)
        cdEntry.update(from: entry, in: context)
        persistence.save()
        fetchEntries(for: entry.petID)
    }

    func deleteEntry(_ entry: JournalEntry) {
        let context = persistence.container.viewContext
        let request = CDJournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)

        do {
            if let cdEntry = try context.fetch(request).first {
                context.delete(cdEntry)
                persistence.save()
                fetchEntries(for: entry.petID)
            }
        } catch {
            print("Delete entry error: \(error.localizedDescription)")
        }
    }
}
