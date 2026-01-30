import CoreData
import SwiftUI

@MainActor
final class HealthRecordViewModel: ObservableObject {
    @Published var records: [HealthRecord] = []

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    var upcomingRecords: [HealthRecord] {
        records
            .filter { $0.nextDueDate != nil }
            .sorted(by: { ($0.nextDueDate ?? .distantFuture) < ($1.nextDueDate ?? .distantFuture) })
    }

    var overdueRecords: [HealthRecord] {
        records.filter { $0.isOverdue }
    }

    var dueSoonRecords: [HealthRecord] {
        records.filter { $0.isDueSoon }
    }

    func fetchRecords(for petID: UUID) {
        let context = persistence.container.viewContext
        let request = CDHealthRecord.fetchRequest()
        request.predicate = NSPredicate(format: "pet.id == %@", petID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDHealthRecord.dateAdministered, ascending: false)]

        guard let results = try? context.fetch(request) else { return }
        records = results.map { $0.toHealthRecord() }
    }

    func fetchAllRecords() {
        let context = persistence.container.viewContext
        let request = CDHealthRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDHealthRecord.nextDueDate, ascending: true)]

        guard let results = try? context.fetch(request) else { return }
        records = results.map { $0.toHealthRecord() }
    }

    func addRecord(_ record: HealthRecord) {
        let context = persistence.container.viewContext
        let cdRecord = CDHealthRecord(context: context)
        cdRecord.id = record.id
        cdRecord.name = record.name
        cdRecord.recordType = record.recordType.rawValue
        cdRecord.dateAdministered = record.dateAdministered
        cdRecord.nextDueDate = record.nextDueDate
        cdRecord.notes = record.notes
        cdRecord.reminderEnabled = record.reminderEnabled
        cdRecord.createdAt = record.createdAt

        let petReq = CDPet.fetchRequest()
        petReq.predicate = NSPredicate(format: "id == %@", record.petID as CVarArg)
        if let cdPet = try? context.fetch(petReq).first {
            cdRecord.pet = cdPet
        }

        persistence.save()

        if record.reminderEnabled, let dueDate = record.nextDueDate {
            NotificationService.shared.scheduleHealthReminder(for: record)
        }

        fetchRecords(for: record.petID)
    }

    func updateRecord(_ record: HealthRecord) {
        let context = persistence.container.viewContext
        let request = CDHealthRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)

        guard let cdRecord = try? context.fetch(request).first else { return }
        cdRecord.name = record.name
        cdRecord.recordType = record.recordType.rawValue
        cdRecord.dateAdministered = record.dateAdministered
        cdRecord.nextDueDate = record.nextDueDate
        cdRecord.notes = record.notes
        cdRecord.reminderEnabled = record.reminderEnabled

        persistence.save()

        NotificationService.shared.removeHealthReminder(for: record.id)
        if record.reminderEnabled, let _ = record.nextDueDate {
            NotificationService.shared.scheduleHealthReminder(for: record)
        }

        fetchRecords(for: record.petID)
    }

    func deleteRecord(_ record: HealthRecord) {
        let context = persistence.container.viewContext
        let request = CDHealthRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)

        guard let cdRecord = try? context.fetch(request).first else { return }
        NotificationService.shared.removeHealthReminder(for: record.id)
        context.delete(cdRecord)
        persistence.save()
        fetchRecords(for: record.petID)
    }
}
