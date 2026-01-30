import CoreData
import SwiftUI

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var events: [TimelineEvent] = []

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func fetchTimeline(for petID: UUID) {
        let context = persistence.container.viewContext
        var allEvents: [TimelineEvent] = []

        // Task completions
        let completionRequest = CDTaskCompletion.fetchRequest()
        completionRequest.predicate = NSPredicate(format: "pet.id == %@", petID as CVarArg)
        completionRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDTaskCompletion.completedAt, ascending: false)]

        if let completions = try? context.fetch(completionRequest) {
            for completion in completions {
                let task = completion.careTask
                allEvents.append(TimelineEvent(
                    id: completion.id ?? UUID(),
                    petID: petID,
                    date: completion.completedAt ?? Date(),
                    eventType: .taskCompleted(
                        taskName: task?.name ?? "Task",
                        taskType: TaskType(rawValue: task?.taskType ?? "custom") ?? .custom,
                        caregiverName: completion.caregiverName ?? "Me"
                    )
                ))
            }
        }

        // Journal entries
        let journalRequest = CDJournalEntry.fetchRequest()
        journalRequest.predicate = NSPredicate(format: "pet.id == %@", petID as CVarArg)
        journalRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDJournalEntry.createdAt, ascending: false)]

        if let entries = try? context.fetch(journalRequest) {
            for entry in entries {
                allEvents.append(TimelineEvent(
                    id: entry.id ?? UUID(),
                    petID: petID,
                    date: entry.createdAt ?? Date(),
                    eventType: .journalEntry(
                        text: entry.text ?? "",
                        hasPhoto: entry.photoData != nil
                    )
                ))
            }
        }

        // Health records
        let healthRequest = CDHealthRecord.fetchRequest()
        healthRequest.predicate = NSPredicate(format: "pet.id == %@", petID as CVarArg)
        healthRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDHealthRecord.dateAdministered, ascending: false)]

        if let healthRecords = try? context.fetch(healthRequest) {
            for record in healthRecords {
                allEvents.append(TimelineEvent(
                    id: record.id ?? UUID(),
                    petID: petID,
                    date: record.dateAdministered ?? Date(),
                    eventType: .healthRecord(
                        name: record.name ?? "",
                        recordType: HealthRecordType(rawValue: record.recordType ?? "vaccination") ?? .vaccination
                    )
                ))
            }
        }

        events = allEvents.sorted { $0.date > $1.date }
    }
}
